# CLAUDE.md

Guidance for working in this repo. Read this before making changes.

## Project

CRM/Taskboard: **Laravel API (`backend/`) + React 19 + Vite (`frontend/`) + `shared/`**.
- Backend: Laravel 13, Sanctum auth (access 60m + rotating refresh 30d), RBAC roles, Reverb (websocket), MySQL, Redis.
- Frontend: React + Vite, React Query, Zustand, react-router, recharts, i18next (vi / en / ja), Tailwind.
- Runs as a full Docker stack; nginx (`web`) on **:8080** fronts php-fpm + serves the built SPA. Dev FE runs via Vite on **:5174** (proxies `/api` → `:8080`).

## Dev environment (IMPORTANT)

- The repo lives **inside WSL2 Ubuntu** (`~/projects/crm-camcom-laravel`). The Bash tool runs on the Windows side and **cannot see `/home/dungbui`** — run shell/`docker`/`npm`/`php artisan` via **PowerShell → `wsl -d Ubuntu bash -lic '…'`**. node/npm are native in WSL via nvm.
- Nested quoting (`{{ }}`, `%{ }`, `()`, `?`) breaks through the PowerShell→wsl→bash layers. For anything non-trivial **write a `.sh` script file, `sed -i "s/\r$//"` it, then run it** (and delete after). Avoid putting regex/format strings inline.
- The backend `app` container live-mounts `./backend` and opcache has `validate_timestamps=1`, so **PHP edits take effect immediately — no rebuild/restart needed**. Migrations: `docker exec -w /var/www/html crm-camcom-laravel-app-1 php artisan migrate --force`.
- **Reboot gotcha:** Docker Desktop's WSL bind mount goes empty after a Windows reboot → `/api/*` returns 404 (`File not found` from php-fpm). Fix: `docker compose up -d --force-recreate app queue scheduler reverb` then `docker compose restart web` (nginx caches the old `app:9000` IP). The repo-root **`start.sh`** does all this; a Windows Scheduled Task `crm-camcom-start` runs it at logon. NEVER run a bare `docker compose up -d` (it re-runs `fe-build` = `npm ci` as root → root-owns `frontend/node_modules`, which breaks the host `npm install`/vite).

## Frontend typecheck (CRITICAL)

The root `tsconfig.json` is **references-only** — `npx tsc --noEmit` against it checks NOTHING (silently passes). **Always** typecheck with:
```
cd frontend && npx tsc --noEmit -p tsconfig.app.json
```
`noUnusedLocals`/`noUnusedParameters` are on — remove unused imports/vars. Do NOT `npm run build` to verify FE (user uses the Vite dev server + HMR).

## Verifying API changes

Mint a Sanctum token in tinker and curl `:8080`, then delete the token:
```
docker exec -w /var/www/html crm-camcom-laravel-app-1 php artisan tinker --execute '$u=App\Models\User::whereHas("assignedRole",fn($q)=>$q->where("key","owner"))->first(); echo $u->createToken("tmp")->plainTextToken;'
```
(The seed login `admin@taskboard.dev/password123` and `b1dung@sougo-career-vietnam.com/@admin123` may be stale/locked — prefer minting a token.)

## Backend (Laravel) — patterns to follow

Layout: `app/Http/Controllers`, `app/Http/Resources`, `app/Models`, `app/Services` (complex logic e.g. `ReportService`), `app/Support` (`PermissionCatalog`, `TaskFilters`), `app/Jobs` (queued), `database/migrations`, `database/seeders/DatabaseSeeder.php`, `routes/api.php`.

**Models**: UUID PKs — `use HasUuids; protected $keyType='string'; public $incrementing=false;`. Mass-assignable via `protected $guarded = [];`. Casts go in a `casts(): array` method (decimals `decimal:2`, dates, json `array`, bool). Some legacy tables have only `created_at` → `public $timestamps = false;`. `Task` uses `SoftDeletes`. Relations are explicit methods (`belongsTo`/`hasMany`/`belongsToMany`); note `User::assignedRole()` (the `role` enum column shadows `role`).

**Resources** (`app/Http/Resources/*Resource.php`): `toArray()` returns **camelCase** keys (the FE contract). Optional relations: `$this->whenLoaded('rel', fn () => …)`. Nested: `new XResource(...)` / `XResource::collection($this->whenLoaded('x'))`. Keep DB→API casing translation here (e.g. `'qaAssigneeId' => $this->qa_assignee_id`).

**Controllers**: validate with `$request->validate([... => ['nullable','uuid'], ...])`. Return via response macros: `response()->ok($data)`, `response()->ok(new Resource(...), 201)`, `response()->paginated(Resource::collection($x), $page, $limit, $total)`, `response()->streamDownload(...)`. Define an `EAGER` const for `->with([...])`. Use `findOrFail`. Update pattern: iterate an `[$inputKey => $dbColumn]` map guarded by `$request->has($in)`; `sync()` for pivots. Fire side-effects: `$this->activity->record(...)`, `$this->notifications->taskEvent(...)`, `ProjectEvent::dispatch(...)`.

**Response envelope**: success `{ success:true, data }`; errors `{ success:false, message }` (string or string[]). The exception handler (`bootstrap/app.php`) renders all `/api/*` as JSON: validation→422 (message = flattened errors), auth→401. `apiPrefix` is `api/v1`; project routes are nested under `projects/{projectId}` and gated by `->middleware('permission:<key>')`. Adding a route = import the controller + add the line in `routes/api.php`.

**Migrations**: one new file per change — **never edit an applied migration**. Reseeding isn't automatic; write a data migration when changing existing rows (e.g. granting a new permission to existing roles). Cross-DB: tests use **SQLite**, dev/prod **MySQL**. SQLite can't add FK constraints/indexes via `ALTER` and ignores `->after()` — guard FK/index adds with `Schema::getConnection()->getDriverName() !== 'sqlite'`. Status filtering / shared query filters go through `$this->filters($query, $request)`.

**Don't**: change `config('app.timezone')` (UTC is intentional); attribute logged time to the logger (use assignee/qa_assignee); group "status" by the enum when a board column exists.

## Exporting for the dev site (DB dump + backend zip)

The dev site **can't run any commands** (no shell/Composer/artisan) — code is uploaded ready-to-run and the DB is imported via a control panel. When asked to "export DB" and/or "zip backend", just produce the artifacts at the repo root with the two committed helper scripts — **don't re-ask about options** (always **include `vendor/`**, always **exclude `.env`**):

```
# DB dump → taskboard-dump-<ts>.sql  (mysqldump from the mysql container, root/root, db `taskboard`)
wsl -d Ubuntu bash -lic 'cd ~/projects/crm-camcom-laravel && sed -i "s/\r$//" dump-db.sh && chmod +x dump-db.sh && ./dump-db.sh'

# Backend zip → backend-laravel-<ts>.zip  (uses python3 zipfile; `zip` CLI is NOT installed in WSL)
wsl -d Ubuntu bash -lic 'cd ~/projects/crm-camcom-laravel && python3 zip-backend.py'
```

- `dump-db.sh`: `docker exec crm-camcom-laravel-mysql-1 mysqldump -u root -proot --single-transaction --no-tablespaces --routines --triggers taskboard`. Includes the `migrations` table (so the dev app's migration state matches — no re-migrate needed) and `DROP TABLE IF EXISTS` (overwrites). No `CREATE DATABASE`/`USE` → pick the target schema in the panel.
- `zip-backend.py`: zips `backend/` (arcname-prefixed `backend/`) **including `vendor/`** so it runs without Composer; excludes `.env` (keeps `.env.*example`/`.env.docker`), `.git`, `node_modules`, and `storage/logs|framework/cache|sessions|views` runtime files. ~35 MB.
- These two `.sh`/`.py` helpers are kept at the repo root on purpose (re-export tools) — don't delete them. The generated `*.sql`/`*.zip` artifacts are throwaway.

**PHP version is pinned to 8.3 to match the dev site (`task.vccdev.vn`).** This was the cause of a dev-site 500: composer had resolved deps under the local container's PHP 8.4 → pulled **Symfony 8** (requires PHP ≥ 8.4.1) and baked `>= 80401` into `vendor/composer/platform_check.php`, which runs before Laravel boots and `throw`s a **non-JSON 500 on every route** (incl. `/api/v1/health/live`) on the 8.3 host. Now locked down: `composer.json` has `config.platform.php = "8.3.0"`, both `backend/Dockerfile` + `Dockerfile.prod` are `php:8.3-fpm-alpine`, and `composer.lock`/`vendor/` are re-resolved to **Symfony 7.4** (8.3-compatible, `laravel/framework` stays `^8.3`). **Keep it 8.3** — don't let composer re-resolve under a higher PHP without the platform pin. To re-run composer for this project use the helper image (the runtime image has no `composer` on PATH): `docker build -t crm-composer:latest - < docker/composer.Dockerfile` then `docker run --rm -u 0 -e COMPOSER_ALLOW_SUPERUSER=1 -v "$PWD/backend":/app -w /app crm-composer:latest update`. After any `vendor/` rebuild, confirm `vendor/composer/platform_check.php` still says `>= 80300` before zipping.

## Production go-live (`task.mintoku.vn`)

Shared-hosting layout in `deploy/shared-hosting/`: `laravel/` (app, outside docroot) + `public_html/` (docroot; `index.php` bootstraps `../laravel`). The **production server can't run ANY command** → everything is built locally and uploaded. Full guide + checklist in `UPDATE-PRODUCTION.md`; template `backend/.env.production.example`.
- **`.env`** lives at `deploy/shared-hosting/laravel/.env` (real secrets there). **`APP_KEY` must be generated locally** (`docker exec … php artisan key:generate --show`) and pasted in — server can't run `key:generate`. No `config:cache`/`route:cache` on the server (app reads `.env` at runtime, which is fine); if a stale `bootstrap/cache/config.php` exists on the server, **delete it** (it overrides `.env`). `public/index.php` was hacked once → always ship the clean stock front controller.
- **DB**: server can't `migrate` → import a SQL dump. Clean seed dump = create a temp MySQL DB, `migrate --seed` into it (override `-e DB_DATABASE=… -e DB_USERNAME=root -e DB_PASSWORD=root`), `mysqldump` (no `CREATE DATABASE`/`USE`, includes `migrations`), then drop the temp DB. Seed (`DatabaseSeeder`) = 6 roles + 1 owner (`b1dung@sougo-career-vietnam.com` / `@admin123`) + default app_settings; **no business data**.
- **Realtime = Pusher cloud** (not Reverb). Backend `.env`: `BROADCAST_CONNECTION=pusher` + `PUSHER_APP_*` + `PUSHER_APP_CLUSTER=ap1` (verify cluster in the Pusher dashboard). FE production build reads **`frontend/.env.production`** (`VITE_BROADCASTER=pusher`, `VITE_PUSHER_APP_KEY`, `VITE_PUSHER_CLUSTER`) — Vite auto-loads it for `vite build`; these MUST match the backend key/cluster. Build with `npm run build` then upload `frontend/dist/`. (Don't rely on inline shell env for the build — a `.env.production` file is the reliable way; `VITE_API_URL=/api/v1` is relative so it's host-agnostic.)

## Frontend (React) — patterns to follow

Layout: `src/api/*.ts` (one typed axios client per domain), `src/pages/<feature>/*`, `src/components/ui` (Button, Avatar, Select, Skeleton, Modal, ConfirmDialog…), `src/hooks`, `src/stores` (zustand), `src/layout` (Sidebar, NotificationsDropdown), `src/lib` (utils, timezones, queryClient), `src/i18n/resources.ts`.

**API clients**: build on `apiClient` (axios, `baseURL=/api/v1`, bearer token + refresh interceptor in `src/api/client.ts`). Methods unwrap the envelope: `.then(r => r.data.data)`. Types are `interface`s in the same file. Downloads: `responseType:'blob'` then object-URL + `a.download`.

**Data**: React Query everywhere. `useQuery({ queryKey:['domain', projectId, …filters], queryFn, enabled:!!projectId })`; mutations use `onMutate` (optimistic `setQueryData` + zustand store) → `onSuccess` (set authoritative data + `invalidateQueries`) → `onError` (rollback + toast). Keep query keys consistent so invalidation hits.

**State**: zustand stores — `useAuthStore` (user/tokens, persisted), `useFilterStore` (`board`/`reports` filters, persisted), `useTaskStore`, `useUIStore`. `usePermissions()` → string[]; `useSiteTimezone()` → timezone; `useToast()`.

**Routing**: pages are lazy in `App.tsx` via `lazyNamed`; wrap admin/global routes in `<RequirePermission permission="…">`; add a `Sidebar.tsx` nav item with `requiresPermission`. Task deep-link = board route `?selectedIssue=<id>`.

**Auth public routes**: `/login` and `/register` are wrapped in `PublicOnlyRoute` in `App.tsx`. If `useAuthStore` has both `isAuthenticated` and an `accessToken`, those pages redirect to `/projects`; only logout should clear the token and allow returning to login/register.

**UI**: Tailwind with design tokens (`text-fg`/`text-fg-muted`/`text-fg-subtle`, `bg-bg-surface`/`bg-bg-elevated`/`bg-bg-subtle`, `border-border`, `text-accent`, `text-success/info/warning/danger`). Compose classes with `cn()`. Reuse `@/components/ui`. Modals via `createPortal` + fixed overlay (`z-[60]`). Charts: recharts; use `<Cell>` for per-item colours, white tooltip text on the dark theme.

**i18n**: every user-facing string uses `t('ns.key')`; add the key to **all three** language blocks (vi → en → ja) in `resources.ts`. Keep keys on the existing single-line namespace objects.

**Auth language sync**: login/register pages use `AuthLanguagePicker` at the bottom of the auth card. It renders the site `LanguageFlag` only (no lucide language SVG) and changes i18next before auth. On successful login/register/OAuth callback, use `currentAppLanguage()` and store `{ ...user, language }` via `setAuth`; if backend `user.language` differs, fire-and-forget `usersApi.update(user.id, { language })` so the selected public-page language is preserved inside the app and persisted server-side.

**Adding a Task field end-to-end**: backend migration + `Task` casts/relation + `TaskResource` (camelCase) + controller validation/`EAGER`/sync; then FE `api/tasks.ts` `Task` & `UpdateTaskDto` + the `TaskDetailModal` field (often parameterize an existing field component with a `variant` rather than duplicating). Typecheck with `tsconfig.app.json` and update test fixtures (`__tests__`) that build `Task`/`SubtaskPreview` literals.

## Key conventions

### Board columns are the source of truth for "status"
A task's `status` enum (`todo/in_progress/in_review/done`) is **derived** from its board **column** name (`Task::columnNameToStatus`). Custom columns (e.g. "Fix") map to one enum but should display their **own name + colour**, not the generic enum label. When showing/changing status, prefer the column:
- Changing status = move the task to a column (`{ columnId }`), let the backend re-derive `status`.
- To display status, use the column name/colour. Many resources already surface this: `TaskResource.subtasksPreview[].columnName/columnColor`, `TaskResource.columnName/columnColor` (when `column` is eager-loaded), reports `completionRate`/`taskDistribution` group by column (with `color`).
- Already synced: subtask status picker, board card subtask rows, Reports "Completion rate by status" + Developer Report "Task Distribution", My Tasks Status column.

### Timezone
All datetimes are stored in **UTC** (`config('app.timezone')='UTC'`). Display uses a **single site-wide timezone**, NOT per-user:
- Stored in `app_settings` (key `timezone`), read via `GET /settings` (any user), written via `PUT /settings` (perm `manage_settings`). Default `Asia/Ho_Chi_Minh`.
- FE: `useSiteTimezone()` hook; `lib/timezones` keeps a module global synced so `formatDate`/`formatRelative` follow it. The per-user `users.timezone` column was **removed**.
- Exports convert via `AppSetting::get('timezone', …)`.

### Task fields (added this codebase)
- `assignee_id` + `qa_assignee_id` (QA Assignee), `estimated_hours`/`logged_hours` + `qa_estimated_hours`/`qa_logged_hours` (QA time tracking). Work logs (`working_hours`) carry `is_qa`.
- **Labels** are surfaced in the task-detail UI as **"Company"**; **Requesters** are a separate label-like entity (`requesters` + `task_requesters`) shown as the "Requester" field.
- Reports "Working hours": logged time is attributed to the **assignee** (dev logs) / **qa_assignee** (QA logs), not whoever logged it.

### Permissions / roles
RBAC: `users.role_id → roles.permissions[]` (catalog in `app/Support/PermissionCatalog.php`). Routes gate with `->middleware('permission:<key>')`; FE with `<RequirePermission permission="…">` + `usePermissions()`/Sidebar `requiresPermission`. Owner & admin roles get most perms incl. `manage_settings`. New permissions must be added to the catalog, the seeder, AND a migration that grants them to existing roles.

### Exports
Styled `.xlsx` via PhpSpreadsheet (perm `view_reports`): green bold header (`#63d297`), zebra rows (`#e7f9ef`/white), thin borders, vertical-centered, auto-width, real hyperlinks (`{baseUrl}/projects/{pid}/tasks?selectedIssue={id}`), time columns `"22.5h"` via `formatDuration()`, datetimes in the site timezone. FE always passes `baseUrl: window.location.origin`.
- `ExportController::tasksXlsx` (`GET …/export/tasks/xlsx`): task list. Columns A..T (20) — note **`Reporter` sits after `Company`** (between Company and Assignee), time cols R/S/T. Adding/moving a column shifts `$lastCol` + the time-column alignment range, so keep them in sync.
- `ExportController::developerReportXlsx` (`GET …/export/developer-report/xlsx?from&to&userId&priority&baseUrl`): styled Developer Report — KPI band + developer leaderboard + task-details table (Calibri font, title band). Reuses `ReportService::developer()` (so `ExportController` injects `ReportService`). FE `reportsApi.exportDeveloperReportXlsx` downloads the blob; the saved filename adds a `yyyyMMdd-HHmmss` timestamp client-side (FE `a.download` overrides the server Content-Disposition name).

### File uploads / storage
All user uploads live under ONE in-repo folder — disk `uploads` = `storage/app/uploads/` (`backend/config/filesystems.php`):
- **Attachments** (task files + inline description images): `storage/app/uploads/attachments/<uuid>.<ext>` (`AttachmentController`, `DISK='uploads'`). Served only via authed API (`…/attachments/{id}/download`, `…/attachments/file/{filename}`) — the stored `file_url` `/uploads/attachments/…` is just a reference, not a static path.
- **Avatars**: `storage/app/uploads/avatars/<uuid>.<ext>` (`UsersController::uploadAvatar`). Public URL `/uploads/avatars/{filename}` is served by the `routes/web.php` route (no `storage:link` needed; nginx `location ~ ^/(api|uploads)` → php-fpm).
- The two folders are tracked via committed `.gitignore` markers (their contents are git-ignored). **`zip-backend.py` ships the folder structure but EXCLUDES the files** (`storage/app/uploads/*`, keeping `.gitignore`/`.gitkeep`), so a redeploy never carries or overwrites uploaded files. On a prod update: never delete `storage/` (uploads + `.env` live there); `chmod -R 775 storage`. Switching the disk root or to S3 = just change the `uploads` disk in `filesystems.php`.

### Deep-linking a task
The board opens a task from `?selectedIssue=<taskId>` and stays in sync with the URL (notification clicks / deep links). When adding new task entry points, navigate to that URL.

### Realtime sync (site-wide)
**Every page** stays in sync via ONE global provider — do NOT add per-page sockets. `frontend/src/layout/RealtimeSync.tsx` (mounted once in `AppLayout`) subscribes to the active project channel `project.{id}` (projectId parsed from the URL) + the user channel `user.{id}`, and on ANY event invalidates **every React-Query query whose key includes that projectId** (predicate). So a new project-scoped page needs nothing extra to be realtime — just keep `projectId` in its `queryKey`. `usePrivateChannel` (`hooks/useSocket.ts`) is **ref-counted** so the global provider + BoardPage can share `project.{id}` without one's unmount `leave()`-ing the other.
Backend: every project-scoped mutation broadcasts `ProjectEvent::dispatch($projectId, '<name>', [...])` (`ShouldBroadcastNow`). Events: `task:created|updated|moved|deleted` (incl. archive/unarchive/restore/log-time → `task:updated`), `column|member|sprint|label|requester|attachment|tasklink:changed`, `comment:added|updated|deleted`. Payload can be minimal (FE only invalidates). **When you add a mutating endpoint, dispatch a ProjectEvent** so all pages sync. Broadcaster: local = self-hosted Reverb (`reverb` container, `BROADCAST_CONNECTION=reverb`); production = **Pusher cloud**.

### Comments & invites (gotchas)
- **Comment replies are nested, not flat.** `CommentController::index` returns only top-level comments (`whereNull('parent_id')`), each with a nested `replies` array (`CommentResource`). The FE must consume `comment.replies` — do NOT rebuild replies by filtering a flat list (they aren't top-level entries, so they'd vanish). Threads are kept one level deep: a reply to a reply attaches to the top-level comment (`replyTo.parentId ?? replyTo.id`).
- **Invites send email.** `InviteController::create` injects `MailService` and emails the register link to the invitee (wrapped in try/catch so SMTP failure doesn't fail the invite); it still returns `link` + `emailSent` for the admin UI. Mail is only sent for real when `MAIL_*` SMTP is configured (`MAIL_MAILER=log` locally).

## Conventions

- Match existing code style; FE labels use i18next `t()` — add keys to all **3** languages (vi/en/ja) in `frontend/src/i18n/resources.ts`.
- After editing a file via the `\\wsl.localhost` path, the executable bit can be stripped — `chmod +x` shell scripts before running.

## TODO — i18n sweep (convert ALL hardcoded UI text to 3 languages)

Goal: every user-facing string (column/section titles, input placeholders, button text, labels, tooltips, toasts, menu items) goes through i18next `t()` with keys added to **all 3** blocks (vi → en → ja) in `frontend/src/i18n/resources.ts`. Keys live on the existing **single-line** namespace objects (`common`, `taskDetail`, `board`, …). Verify with `cd frontend && npx tsc --noEmit -p tsconfig.app.json` (root tsconfig checks nothing). Components without the hook need `const { t: tr } = useTranslation()` added. Module-level const label maps (e.g. `STATUS_META`/`PRIORITY_META` `.label`) must be translated **at render** (lookup `t()` by key), not in the const.

**Done**
- `TaskDetailModal.tsx` — core interactive text: tab labels, Detail field/section labels (Assignee/QA Assignee/Priority/Due date/Requester/Reporter/Time tracking/QA time tracking/Parent/Team/Start date/Details/Development), Description/Subtasks/Linked-items headings + Save/Cancel/Add/Link buttons, Comments tab (placeholder, "Press M", quick replies, edit Save/Cancel, "(edited)"), Work Log tab, Time Tracking modal (all labels/placeholders/radios/Cancel + toast + format errors + display), History tab (actor avatar+name, action labels, field diff labels, "logged Nh"/QA, None/Unassigned/Unknown user/System), DetailHeader overflow menu. Keys added under `common` (`unassigned`,`add`) and `taskDetail` (large batch).
- `LoginPage.tsx` / `RegisterPage.tsx` — form labels/placeholders, 2FA label/validation, forgot-password link, invite/pending states, and auth language picker are translated. Language picker sits at the bottom and uses the same country-flag icon style as the in-app account menu.
- Public auth language now stays in sync after login/register/OAuth: selected language is written into auth store and persisted to the user profile when needed.
- `NotFoundPage.tsx`, `ErrorBoundary.tsx`, `ForgotPasswordPage.tsx`, `ResetPasswordPage.tsx`, `VerifyEmailPage.tsx`, `SecureImage.tsx`, `NotificationsDropdown.tsx`, account session/2FA sections, and remaining obvious user-management email labels/placeholders have been moved to i18n keys.
- `/login` and `/register` are public-only routes: an authenticated user with an access token is redirected to `/projects` unless they logout.

**Remaining in `TaskDetailModal.tsx`**
- `STATUS_META` / `PRIORITY_META` `.label` (To Do/In Progress/In Review/Done; Urgent/High/Medium/Low/Lowest) — translate at render; check `board` namespace for existing status/priority keys to reuse.
- Editor toolbar `title=` tooltips (Bold/Italic/Heading/Link/…), DetailHeader `title=` tooltips (Copy task ID/Watch/Share/Open full page/Add child task), `TitleEditor` placeholder, `AttachmentsSection`, `CreateBranchPanel`, `SubtaskStatusPicker` text, `'2h 30m'` sample placeholder.

**Remaining files** (grep each for hardcoded JSX text / `placeholder="…"` / `label: '…'` / button children):
- `src/pages/board/BoardPage.tsx` + board column headers/card menus/inputs.
- `src/pages/users/UserManagementPage.tsx`; `src/layout/Sidebar.tsx`.
- `src/pages/reports/*`, `projects/*`, `settings/*`, `my-tasks/*` (33 page files total) and `src/components/ui/*`.
- Sweep helper: `grep -rnE 'placeholder="[A-Za-z]|>[A-Z][a-z]+ ?[A-Za-z ]*<' src/pages src/components src/layout`.
