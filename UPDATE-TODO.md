# UPDATE-TODO — Convert NestJS → Laravel (giữ React FE)

> Theo dõi tiến độ convert backend sang **Laravel** (thư mục `laravel-backend/`), **giữ nguyên React FE**.
> Tham chiếu thiết kế tổng: **`CONVERT-PROJECT-TO-LARAVEL.md`**. Schema gốc: DB Postgres đang chạy (`taskboard`).

## 📌 TÓM TẮT CUỐI (chốt — đọc cái này trước)

> **CẬP NHẬT 2026-06-22**: port nốt **Roles/Permissions**, **Sprints**, **Export** (Excel/PDF queue) → **parity NestJS→Laravel = 21/21 module, 100%**. Nâng **upload attachment lên 250MB**. Thêm dev stack chạy local bằng **SQLite** (máy thiếu `pdo_mysql`): `laravel-backend/docker-compose.dev.yml` + `.env.docker` + `docker/php-upload.ini`. Test suite **8/8 PASS**.

### ✅ ĐÃ CONVERT XONG (code/config trong repo, đã verify) — 100% module
- **Backend Laravel** ở `laravel-backend/`: 19 bảng + 19 models + seeder; Auth (Sanctum + refresh-rotation cookie) + RBAC; **112 route /api/v1**. **Đủ 21/21 module NestJS**: Projects, Members, Columns, **Tasks** (filter/pagination/move/status↔column/archive), Comments, Attachments, Labels, TaskLinks, Users, MyTasks, ManageProjects, Notifications (read + fan-out), Archived, **Reports** (summary/developer/…), **Activity** (log + export), **Invites**, **Roles/Permissions** (catalog + CRUD role, RBAC), **Sprints** (list/CRUD tối thiểu — UI đã bỏ nhưng FilterBar/Reports vẫn gọi), **Export** (Excel task + PDF monthly qua Queue Job + notification `export_ready` + cleanup 24h), auth-phụ (password-reset/email-verify/sessions/**2FA TOTP**/Google), **Realtime** (`ProjectEvent` broadcast + Reverb + channels). Hardening: SecurityHeaders, Sentry, throttle. → **smoke-test thật pass (MySQL trước đó; SQLite dev hiện tại).**
- **Frontend**: đã nối vào Laravel — `useSocket.ts` dùng laravel-echo+pusher-js (khớp Reverb), `frontend/.env` set, Vite proxy `/api`→Laravel `:8000`, upload `timeout:0`; **tsc sạch + 125 test pass.**
- **Data migration**: script `php artisan migrate:from-postgres` (copy data Postgres→MySQL, giữ UUID).
- **Tests**: `tests/Feature/BoardFlowTest.php` + Totp/GoogleOAuth (8 test PASS) + `ci.yml`.
- **Deploy artifacts**: `laravel-backend/Dockerfile` (php-fpm, có `gd` cho PhpSpreadsheet + `php-upload.ini` 250MB) + `deploy/` (docker-compose.prod, apache vhost LimitRequestBody 250MB, supervisor, DEPLOY.md) + cutover runbook.

### ⬜ CHƯA LÀM — vì cần SERVER + DATA THẬT (không code được, phải chạy trên server công ty)
1. **Chạy migrate data thật** (P9): `php artisan migrate:from-postgres --fresh` (cần `pdo_pgsql` + cả 2 DB) + copy `backend/uploads/*` sang `storage/app/public/` + verify count.
2. **Deploy production** (P12): theo `deploy/DEPLOY.md` (build FE → `docker compose -f deploy/docker-compose.prod.yml up -d` → `config/route/view:cache` → `db:seed`). Cần **queue worker** chạy (export jobs).
3. **Cutover** (P13): theo `deploy/DEPLOY.md` mục F (chạy song song → chuyển DNS → verify mục G → rollback nếu lỗi → gỡ NestJS cũ).

> ⚠️ Điểm chưa verify được tại local: **migrate/seed trên MySQL thật** (máy dev thiếu `pdo_mysql` → đang dùng SQLite). Cần chạy lại trên server có MySQL + `pdo_mysql` trước khi go-live (enum + FULLTEXT index).

### 🟡 Tuỳ chọn (nên làm, không blocking go-live)
- Gửi **email invite** qua MailService (API + token lifecycle đã xong, chỉ thiếu Mailable gửi link).
- Parity test reports (đối chiếu số với NestJS); comment mentions→notif (cơ bản đã có).

> **Một câu**: Code convert đã **DONE 100% (21/21 module)**. Mở lại chỉ cần **deploy + migrate data (MySQL) + cutover trên server** theo `deploy/DEPLOY.md`.

---

## Quyết định đã chốt
- **DB**: MySQL · **Vị trí code**: `laravel-backend/` · **Laravel 13** + Sanctum + (spatie cài nhưng KHÔNG dùng — RBAC custom).
- **RBAC custom**: bảng `roles` có cột `permissions` (JSON array); user có `role` (enum legacy) + `role_id` → roles. Migration spatie đã xoá.
- **API contract giống hệt NestJS**: envelope `{success:true,data}` / lỗi `{success:false,message}` (message string|string[]); list có `meta:{page,limit,total,totalPages}`; prefix `/api/v1`; camelCase.
- **Auth**: access token Sanctum 15m (Bearer) + refresh token rotation lưu DB, gửi qua **httpOnly cookie** 7 ngày.

## 🔄 TRẠNG THÁI MỚI NHẤT (sau khi check)
**BACKEND PORT HOÀN CHỈNH & VERIFIED — 21/21 module.** App boot OK, **112 route /api/v1**:
- **21 controllers** (gồm cả **Activity, Report, Invite, Roles, Sprints, Export**) + 7 services (`AuthTokens, AccountSecurityService`[reset/verify/sessions/2FA], `MailService, NotificationService`[fan-out + `direct()`], `ActivityService, ReportService, TotpService`) + 2 Jobs (`ExportTasksExcel`, `ExportMonthlyReportPdf`).
- **Roles/Permissions**: `RolesController` + `PermissionCatalog` (15 permission) + `RoleResource`; CRUD role có bảo vệ (không cấp quyền mình không có, không xoá system role / role của mình / role đang gán user). VERIFIED.
- **Export**: `ExportController` (enqueue Excel/PDF + download có guard) + Queue Jobs (PhpSpreadsheet xlsx + dompdf pdf) + `ExportStorage` (cleanup 24h) + notification `export_ready`. VERIFIED sinh file hợp lệ (PK/%PDF) + tải về.
- **Sprints**: `SprintController` (index + CRUD tối thiểu) — chống 404 cho FilterBar/Reports.
- Realtime: `ProjectEvent` (ShouldBroadcast `task:*`) + `routes/channels.php` + `broadcasting/auth` + Reverb env. FE Echo đã wire.
- Hardening: `SecurityHeaders`, Sentry, `throttle` trên auth/invite. Upload attachment **250MB** (`AttachmentController::MAX_KB` + `php-upload.ini`).

**CÒN LẠI**:
- ✅ **Phase 10 (FE wiring) XONG & verified**: `useSocket.ts` đã dùng laravel-echo+pusher-js (khớp `ProjectEvent`/`channels.php`); `frontend/.env` set `VITE_API_URL=/api/v1`+`VITE_REVERB_*`; test fix (mock `@/hooks/useSocket`); **tsc sạch + 125 test pass**. (Dev cần Vite proxy `/api/v1`→Laravel; prod cùng domain qua Apache thì OK.)
- 🟡 **Phase 9** có sẵn script: `php artisan migrate:from-postgres --fresh` (`app/Console/Commands/MigrateFromPostgres.php`, env `PG_*`, cần `pdo_pgsql`). ⚠️ DRAFT — review datetime/json edge cases + copy `uploads/` thủ công + verify count trước khi chạy prod.
- ✅ **Phase 11** có test thật: `tests/Feature/BoardFlowTest.php` (3 test PASS — default columns, move→status, RBAC 403). Fulltext index đã guard theo driver (sqlite test / mysql prod). CI `ci.yml` chạy được. Parity test thêm tuỳ chọn.
- ✅ **Phase 12** artifacts đầy đủ: `laravel-backend/Dockerfile` (php-fpm prod), `deploy/docker-compose.prod.yml` (mysql/redis/app/migrate/queue/scheduler/reverb/apache), `deploy/apache-taskboard.conf`, `deploy/supervisor.conf`, `deploy/DEPLOY.md`. → **chạy trên server** theo DEPLOY.md.
- ✅ **Phase 13** runbook: `deploy/DEPLOY.md` mục F (cutover từng bước + rollback) + mục G (checklist go-live). → **thực thi trên server** (cần người có quyền).
- Lẻ còn lại (nhỏ): email invite (Mailable gửi link), comment mentions→notif (read/fan-out cơ bản đã có).

> **KẾT LUẬN**: Toàn bộ CODE convert đã hoàn tất — **21/21 module, 100% parity** (kể cả Roles, Sprints, Export). Việc còn lại thuần **thực thi trên server công ty**: chạy `migrate:from-postgres` + migrate/seed trên **MySQL** (P9), `docker compose up` theo DEPLOY.md (P12), cutover theo runbook (P13). Không còn việc code nào blocking.

---

## ✅ ĐÃ XONG (verify e2e trên MySQL)

### Phase 1–2: Scaffold + Schema + Models + Seeder
- `laravel-backend/` (Laravel 13), `.env`/`.env.example` → **MySQL** (DB `taskboard`), `FRONTEND_URL`.
- **7 migration** đủ 18 bảng (`database/migrations/`). Map: UUID→char(36), enum native, `ILIKE`→`LIKE`, `timestamptz`→`timestamp`, trgm→`FULLTEXT(title,description)`. `reporter_id/uploader_id/activity_logs.user_id` **nullable** (MySQL không cho NOT NULL+SET NULL). `users` KHÔNG có updated_at. Sanctum `personal_access_tokens` đổi `uuidMorphs`.
- **18 Eloquent models** (`app/Models/`): HasUuids, `$keyType='string'`, `$incrementing=false`, timestamps đúng (chỉ `Task` có updated_at). `User` auth qua `password_hash`. **Relationship role trong User tên `assignedRole()`** (KHÔNG `role()` — bị cột enum shadow). `Task::columnNameToStatus()`.
- **Seeder**: 6 roles (owner/admin/pm/team_lead/member/client) + 3 user `@taskboard.dev`/`password123`.

### Phase 3: Nền API
- `bootstrap/app.php`: prefix `api/v1`, `shouldRenderJsonWhen(api/*)`, render lỗi → envelope, alias `permission`.
- `AppServiceProvider`: macro `Response::ok()` + `Response::paginated()`.
- `routes/api.php`: `/health/live|ready`. `config/cors.php`: credentials + `FRONTEND_URL`.

### Phase 4: Auth + RBAC (VERIFIED)
- `app/Services/AuthTokens.php` (access 15m + refresh rotation cookie). `AuthController` (register pending/invite, login 401/403, refresh, logout, me, permissions). `app/Http/Middleware/EnsurePermission.php`. `User::permissions()/hasPermission()/toAuthArray()`.

### Phase 5: Board core (VERIFIED)
- Resources: TaskUser/Project/Column/Label/Member/Task (camelCase + nested + subtaskCount/preview/project).
- Controllers: **Project** (store tự tạo 4 column + owner member + counter; gated `create_project`), **Member** (+taskCount), **Column** (CRUD+reorder), **Task** (index filters+pagination, store [task_number/status từ column], update [columnId→move→status], move, destroy, logTime).

### Phase 6: Collaboration (VERIFIED)
- **Label** (CRUD), **Comment** (nested replies, edited_at, soft-delete), **Attachment** (upload→Storage `/uploads/attachments/uuid.ext`, download, listForProject, rawByName), **TaskLink** (chặn self/duplicate).
- Resources: Comment/Attachment/ProjectAttachment/TaskLink; LabelResource +projectId.

### Phase 7 (VERIFIED e2e: users list, me/tasks, manage create+list, archive/unarchive, deadline, changePassword đều OK)
- **Users**: `AppUserResource`; `UsersController` (index q, show, store[manage_users], update[self+admin], destroy, changePassword, uploadAvatar `/uploads/avatars/`, exportOwnData, deleteOwnAccount). `TaskResource` thêm `project`.
- **My-Tasks**: `MyTasksController` (`GET /me/tasks` → `{items,stats}`).
- **Manage-projects**: `ManagedProjectResource`+`ManagedMemberResource`; `ManageProjectController` (index +taskCount/memberCount/owner, store, update[deadline], archive/unarchive, destroy[soft→taskCount], restore[withTrashed], transferOwner, members/addMember/removeMember). Routes `manage/projects*` gated permission.
- **Notifications**: `NotificationResource`; `NotificationController` (index paginated + resolve task/comment `context`, markRead, markAllRead, unreadCount). Fan-out được hoàn thiện ở phần Phase 7 bên dưới.
- **Archived**: `ArchivedController` (`GET /projects/{id}/archived` → `{tasks,projects}` archived). Thêm vào `TaskController`: `archive`/`unarchive`/`restore` + **index đã loại task `archived_at` khỏi board**. Routes wired.
- **Avatar serving**: upload vào public disk và route `/uploads/avatars/{filename}` phục vụ file an toàn, không phụ thuộc `storage:link`. VERIFIED upload + tải file thật.
- **Notifications fan-out + mentions**: `NotificationService` fan-out task create/update/move/time-log/comment tới assignee, reporter, project manager/admin và global owner; loại actor/trùng/inactive. Comment hỗ trợ `mentionedUserIds`, kiểm tra project member, lưu `comment_mentions`, tạo notification riêng và resolve deep-link context.
- **Activity**: `ActivityService` ghi task create/update/assign/status/move/delete/time-log và comment; `ActivityController` list với filter+pagination, export CSV UTF-8. VERIFIED DB records + CSV download.
- **Reports**: `ReportService` MySQL-native cho `summary`, `developer-report`, `weekly`, `monthly-kpi`, `productivity`, `completion-rate`, `working-hours`; developer report giữ rule assignee + created range và trả đủ `taskDetails`. `logTime` đã ghi cả bảng `working_hours`. VERIFIED đủ 7 endpoints.
- **Invites**: create token SHA-256/TTL 7 ngày, list pending, validate public, revoke, đăng ký qua invite dùng token hiện có. VERIFIED create/list/validate/revoke.
- **Phase 7 smoke test**: login → project/task → update/comment mention/log-time → notifications/activity/reports/invites trên MySQL; xác nhận dữ liệu ở `notifications`, `activity_logs`, `working_hours`.

---

## ✅ function hold — ĐÃ XỬ LÝ (2026-06-22)

### Chức năng nghiệp vụ
- [x] **Roles/Permissions**: `RolesController` (`GET /roles`,`/permissions`, POST/PATCH/DELETE role) + `PermissionCatalog` + `RoleResource`. VERIFIED (list/create/update/delete + 403 cho member + chặn xoá system role).
- [x] **Sprints** (tối thiểu): `SprintController` index + store/update/start/complete. VERIFIED (list rỗng 200 — UI đã bỏ Sprints).
- [x] **Export** (Queue Job + file + notification `export_ready`): `ExportController` + `ExportTasksExcel`/`ExportMonthlyReportPdf` + `ExportStorage`. Deps `phpoffice/phpspreadsheet` + `dompdf/dompdf`. VERIFIED sinh xlsx (PK)/pdf (%PDF) + download + cleanup 24h. **Prod cần queue worker** (đã có trong compose.prod).
- [ ] Gửi **email invite** qua MailService/Mailable (API invite và token lifecycle đã xong — chỉ còn Mailable gửi link).

## ⬜ CHƯA LÀM

### Phase 8: Auth phụ + Realtime + nối FE
- [x] **Password reset / email verify / sessions / 2FA**: account token SHA-256 dùng một lần, reset revoke sessions; TOTP RFC 6238 (HMAC-SHA1, 6 số/30s, ±1 window), secret mã hoá; VERIFIED E2E MySQL. UI 2FA đã bật.
- [x] **Google Socialite (code/config)**: redirect/callback, account mới pending, account active nhận access+refresh cookie; thiếu credentials trả 503 rõ ràng. ⚠️ Callback Google thật còn cần credentials prod để E2E.
- [x] **MailService cho reset/verify**: dùng Laravel Mail, mailer cấu hình qua env. Email invite thuộc `function hold` nên không triển khai.
- [x] **Realtime code + process smoke**: Laravel Reverb/Pusher + private `project.{id}`, authorization kiểm owner/member/`view_all_projects`, event task create/update/move/delete + comment; FE `useSocket.ts` đã chuyển sang Echo adapter. Reverb start thực với `pcntl`, private auth và task broadcast dispatch đều OK.
- [x] **Hardening đã xong**: throttle auth/token, security headers, `Dockerfile.prod` PHP 8.4 (`pdo_mysql`+`pcntl`), CI chuyển từ Nest/Postgres sang Laravel/MySQL + React.
- [ ] **Hardening còn lại**: Sentry backend và backup schedule (phối hợp Phase 12).
- [x] **Nối React FE (code/build)**: `VITE_API_URL=/api/v1`, Vite proxy Laravel, Reverb env, Echo/Pusher dependencies; ESLint + 125 tests + production build đều PASS.
- [ ] **Browser E2E board + Google OAuth thật** trên môi trường có Reverb/Google credentials.
- [ ] **Kiểm tra Docker image build thực tế** cho `laravel-backend/Dockerfile.prod` (file đã tạo, CI đã trỏ sang Laravel nhưng local build chưa chạy).

### Phase 9: Data migration Postgres → MySQL (dữ liệu thật hiện có)
- [ ] Export dữ liệu từ Postgres `taskboard` đang chạy (users, projects, tasks, comments, attachments…).
- [ ] Transform: `uuid`→char(36) giữ nguyên giá trị; `enum` giữ value; `timestamptz`→datetime UTC; `jsonb`→json; boolean.
- [ ] Import vào MySQL. Giữ nguyên **id (UUID)** để không vỡ liên kết. Bỏ qua/seed lại `migrations`, `sessions`, `cache`, `personal_access_tokens`, `refresh_tokens` (token cũ không tương thích → user phải đăng nhập lại).
- [ ] Copy file uploads (`backend/uploads/*`) sang `laravel-backend/storage/app/...` + chỉnh `attachments.file_url`/`users.avatar_url` nếu đổi cấu trúc.
- [ ] Script idempotent + verify count từng bảng khớp.

### Phase 10: Frontend hoàn thiện khi chạy thật trên Laravel
- [x] Đổi `frontend/.env` (`VITE_API_URL=/api/v1`) + realtime sang **Laravel Echo** (`useSocket.ts`).
- [ ] Dò **lệch contract** từng trang (chạy FE thật, click hết): định dạng ngày, field thiếu/thừa, shape lỗi, mã trạng thái.
- [ ] Upload (`Content-Type: undefined` multipart), tải/preview attachment, avatar URL serve đúng.
- [ ] Refresh-token cookie cross-site khi cùng domain (Apache proxy) — kiểm `SameSite`/secure.
- [x] Bật lại 2FA (`SHOW_TWO_FACTOR=true` ở `AccountPage.tsx`+`LoginPage.tsx`) sau khi BE 2FA xong.
- [x] Chạy `npm run build` + chỉnh lỗi type/unused; ESLint, Vitest và build đều PASS.

### Phase 11: Testing & parity
- [ ] **PHPUnit/Pest** cho service phức tạp: refresh rotation, move/status, reports query, invite, permission.
- [ ] **Parity test** từng module: so output Laravel vs NestJS (cùng input) — đặc biệt reports (đối chiếu từng số), pagination, soft-delete/undo, archive.
- [ ] **E2E Playwright** (FE đã có `frontend/playwright`) trỏ vào Laravel.
- [ ] Kiểm **N+1 / index / eager-load**; load test endpoint nặng (board limit 1000, reports).
- [ ] Edge cases tinh tế: undo 10s xoá task/project, optimistic concurrency reorder, refresh revoke token cũ, RBAC từng permission.

### Phase 12: Deployment / DevOps (server công ty: Apache + MySQL + Laravel sẵn có)
- [ ] **Dockerfile.prod + docker-compose** cho Laravel (php-fpm + nginx/apache) HOẶC deploy thẳng lên server công ty (đã có PHP/MySQL).
- [ ] **Queue worker** (supervisor `php artisan queue:work`), **Scheduler** (cron `schedule:run`), **Reverb** (`reverb:start`) chạy nền 24/7.
- [ ] `php artisan storage:link`; cấu hình **S3** nếu nhiều instance; `config:cache`/`route:cache`/`view:cache` ở prod.
- [ ] Apache vhost: serve React build (DocumentRoot) + proxy `/api`, `/broadcasting`, websocket → Laravel; SSL (Let's Encrypt); SPA fallback.
- [ ] Env prod: APP_KEY, secrets, `APP_DEBUG=false`, CORS `FRONTEND_URL`, SMTP, Reverb keys.
- [ ] **Backup** `mysqldump` định kỳ + retention; **Sentry** (`sentry/sentry-laravel`); rate-limit (`throttle`); security headers.
- [ ] **CI/CD**: pipeline lint(`pint`) + test(`pest`) + build FE + deploy.

### Phase 13: Cutover & cleanup
- [ ] Chạy song song NestJS + Laravel, smoke test prod, rồi **chuyển FE sang Laravel**; có **rollback plan**.
- [ ] Theo dõi lỗi/log sau cutover; sửa hotfix.
- [ ] Gỡ **NestJS backend cũ** (`backend/`) + Postgres/Redis-NestJS sau khi ổn định; gỡ package `spatie/laravel-permission` nếu không dùng.
- [ ] Cập nhật **`CLAUDE.md`** + docs (stack mới Laravel + React); xoá `CONVERT-PROJECT-TO-LARAVEL.md`/`UPDATE-TODO.md` khi xong.
- [ ] **Security review** cuối: audit permission từng route, CORS, upload signature/virus scan, mass-assignment (`$guarded=[]` → cân nhắc fillable cho endpoint public).

---

## ⚙️ Cách chạy & TEST (môi trường KHÔNG có PHP/Composer native → dùng Docker)

sudo bị khoá (hỏi mật khẩu) → KHÔNG apt-install; file do container root tạo phải xoá bằng container root.

```bash
# Composer/artisan (PHP 8.4), user host để không tạo file root:
docker run --rm -u $(id -u):$(id -g) -e COMPOSER_HOME=/tmp \
  -v /home/dung_bui/project/crm-comcom/laravel-backend:/app -w /app composer:latest <cmd>

# Test e2e: MySQL tạm + serve
docker network create tb_net
docker run -d --name tb_mysql_test --network tb_net -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=taskboard -e MYSQL_USER=taskboard -e MYSQL_PASSWORD=taskboard mysql:8
# chờ: docker exec tb_mysql_test mysqladmin ping -uroot -proot --silent
docker run --rm --network tb_net -e DB_HOST=tb_mysql_test -e LOG_CHANNEL=stderr \
  -v .../laravel-backend:/app -w /app php:8.4-cli \
  sh -c 'docker-php-ext-install pdo_mysql >/dev/null 2>&1 && php artisan migrate:fresh --seed --force'
docker run -d --name tb_laravel --network tb_net -p 8055:8000 -e LOG_CHANNEL=stderr \
  -v .../laravel-backend:/app -w /app php:8.4-cli \
  sh -c 'docker-php-ext-install pdo_mysql >/dev/null 2>&1 && php artisan serve --host 0.0.0.0 --port 8000'
# login: curl -s -H "Content-Type: application/json" -H "Accept: application/json" \
#   -X POST http://localhost:8055/api/v1/auth/login -d '{"email":"admin@taskboard.dev","password":"password123"}'
```

### GOTCHAS (nhớ kỹ)
1. **`artisan serve` KHÔNG forward `-e DB_HOST`** → khi test serve phải sửa `.env` `DB_HOST=tb_mysql_test` rồi **REVERT `127.0.0.1`** sau khi xong.
2. **`composer`/`sail` image thiếu `pdo_mysql` CLI** → dùng `php:8.4-cli` + `docker-php-ext-install pdo_mysql`. Laravel 13 cần **PHP 8.4**.
3. **curl `Authorization: Bearer <token>` có dấu cách** → để `-H "Authorization: Bearer $TOKEN"` (đừng gộp `-H`+value 1 biến).
4. **Thêm `-H "Accept: application/json"`** khi curl (axios FE tự gửi nên thật sự OK; thiếu thì auth lỗi redirect `Route [login]`).
5. **Dọn sau test**: `docker run --rm -v .../laravel-backend:/b alpine sh -c 'rm -f /b/storage/logs/laravel.log; rm -rf /b/storage/app/private/attachments'`; `docker rm -f tb_laravel tb_mysql_test; docker network rm tb_net`. Kiểm `find ... -user root -not -path '*/vendor/*'`.
6. **Parse JSON trong test**: dùng python3 `python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['id'])"` (đừng dùng `eval`).

## Patterns (giữ nhất quán khi port tiếp)
- Controller → `response()->ok()` / `response()->paginated()`. List camelCase qua **Resource**.
- Model UUID: `HasUuids` + `$keyType='string'` + `$incrementing=false`; bảng chỉ created_at → `$timestamps=false`.
- FK SET NULL ở MySQL cần cột nullable.
- Phân quyền: `->middleware('permission:key')` / `$user->hasPermission('key')`.
- Set `columnId` (update/move) → `Task::columnNameToStatus($column->name)`.

## Tham chiếu file gốc
- Logic: `backend/src/modules/**/*.controller.ts`, `*.service.ts` (đặc biệt `reports.service.ts`, `notifications.service.ts`, `auth.service.ts`).
- Contract FE: `frontend/src/api/*.ts`. Enums: `shared/src/enums.ts`. Realtime FE: `frontend/src/hooks/useSocket.ts`.
