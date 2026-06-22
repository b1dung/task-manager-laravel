# Convert CRM ComCom: NestJS → Laravel (giữ nguyên React FE)

Tài liệu hướng dẫn chuyển **backend** từ NestJS sang **Laravel**, **giữ nguyên frontend React** hiện tại.
Nguyên tắc xuyên suốt: **giữ y hệt API contract** (cùng URL, cùng shape JSON) để React gần như không phải sửa.

---

## 0. TL;DR chiến lược

- **FE React giữ nguyên** → Laravel phải "trả lời giống hệt" NestJS.
- Đổi ở FE chỉ gồm: `VITE_API_URL`, **realtime (socket.io-client → Laravel Echo)**, và (tuỳ) cơ chế refresh token.
- Port BE theo thứ tự: **Auth → RBAC → Projects/Members → Columns/Tasks → Comments/Attachments → Labels → Reports → Notifications → Activity → Invites → Export → Realtime**.
- Realtime (Socket.IO) là phần tốn công nhất → để cuối.

---

## 1. Bản đồ công nghệ NestJS → Laravel

| Thành phần | NestJS (hiện tại) | Laravel |
|---|---|---|
| Ngôn ngữ/Runtime | TypeScript / Node 20 | PHP 8.2+ / Laravel 11 |
| ORM | TypeORM | **Eloquent** + migrations |
| Auth token | JWT access 15m + refresh 7d (cookie) | **Sanctum** (SPA cookie) hoặc token API |
| RBAC | Roles/permissions tự build (DB) | **spatie/laravel-permission** |
| Validation | class-validator + DTO | **Form Request** |
| Queue (export) | Bull + Redis | **Laravel Queue** (Redis) + Job |
| Realtime | Socket.IO | **Reverb** (hoặc Pusher) + **Laravel Echo** ở FE |
| Email | nodemailer | **Mail** (Mailable) |
| File upload | multer | **Storage** (local/S3) |
| Static uploads | ServeStatic | `storage:link` + route |
| Scheduling/cron | (compose backup) | **Task Scheduler** |
| Config/env | @nestjs/config | `config/*.php` + `.env` |
| Error monitoring | @sentry/node | `sentry/sentry-laravel` |

---

## 2. Server & yêu cầu (đã có sẵn vì công ty chạy Laravel + React)

- PHP **8.2+**, Composer
- **MySQL 8** (hoặc giữ PostgreSQL — Eloquent hỗ trợ cả hai)
- **Redis** (queue + cache + Reverb scaling)
- Apache/Nginx (đã có)
- Node chỉ cần để **build React** (hoặc build sẵn ở CI rồi copy `dist/`)
- Nếu dùng realtime: chạy thêm **`php artisan reverb:start`** (1 tiến trình) hoặc dùng Pusher cloud

> Lưu ý: Laravel **không bắt buộc Node chạy 24/7** như NestJS — đây là lý do nó hợp với server hiện có.

---

## 3. API CONTRACT — phải giữ y hệt (QUAN TRỌNG NHẤT)

React đang phụ thuộc các quy ước sau. Laravel **bắt buộc** trả đúng:

### 3.1. Bao response thành công
```json
{ "success": true, "data": <payload> }
```
→ Làm 1 helper/Resource hoặc middleware bọc mọi response. Ví dụ macro:
```php
// AppServiceProvider::boot()
Response::macro('ok', fn ($data, $status = 200) =>
    response()->json(['success' => true, 'data' => $data], $status));
```

### 3.2. Response lỗi
```json
{ "success": false, "message": "..." }   // message: string HOẶC string[]
```
FE đọc `response.data.message` (nếu là mảng lấy phần tử đầu). → Tuỳ biến `Handler::render()` / exception handler để mọi lỗi ra đúng shape này. Validation 422 nên trả `message` là mảng các lỗi.

### 3.3. Phân trang (list tasks…)
```json
{ "success": true, "data": [ ... ], "meta": { "page": 1, "limit": 50, "total": 120, "totalPages": 3 } }
```
→ Không dùng paginator mặc định của Laravel (shape khác). Tự build `meta` đúng field trên.

### 3.4. Prefix & versioning
- Tất cả route dưới **`/api/v1/...`** (đặt trong `routes/api.php` với prefix `v1`, hoặc `RouteServiceProvider`).

### 3.5. Auth contract (đọc kỹ — khác token thường)
| Việc | Hành vi hiện tại | Laravel làm gì |
|---|---|---|
| Access token | `Authorization: Bearer <accessToken>`, sống ~15 phút | Sanctum token ngắn hạn, hoặc access JWT |
| Refresh token | **httpOnly cookie**; FE gọi `POST /auth/refresh` body `{}` + `withCredentials` → nhận `{ data: { accessToken } }` | Lưu refresh trong **cookie httpOnly**; endpoint refresh đọc cookie, xoay vòng (revoke cũ, phát mới) |
| Login trả về | `{ user, accessToken, refreshToken }` (`success/data`) | Trả y hệt; set refresh cookie kèm theo |
| Logout | `POST /auth/logout` | Revoke refresh hiện tại + xoá cookie |
| `GET /auth/me` | trả `AuthUser` | trả đúng các field user FE cần |

> **Khuyến nghị**: dùng **Sanctum SPA (cookie)** cho refresh + access token Bearer. Cơ chế "refresh rotation" (revoke token cũ, phát cặp mới) tự viết trong controller `refresh()`.

`AuthUser` (shape FE cần — kiểm tra `frontend/src/stores/useAuthStore.ts`): tối thiểu
`id, email, fullName, role, avatarUrl, timezone, language, appearance, twoFactorEnabled, ...`

---

## 4. Database: Entities → Eloquent + Migrations

### 4.1. Danh sách bảng cần port (18 entity)
| Bảng | Ghi chú khi port |
|---|---|
| `users` | + cột bảo mật: `two_factor_secret` (mã hoá), `two_factor_enabled`, `email_verified_at`, preferences (`timezone`, `language`, `appearance`) |
| `roles` | RBAC động (tên + mô tả + cờ system) |
| `refresh_tokens` | token xoay vòng; lưu hash, `expires_at`, `revoked_at`, `user_id` |
| `account_tokens` | token reset password / verify email (loại + hết hạn) |
| `projects` | + lifecycle: `archived_at`, `deadline`, `slug`, `owner_id` |
| `project_members` | pivot user↔project + role trong project |
| `columns` | board column: `name`, `position`, `color`, `wip_limit` |
| `tasks` | xem mục 4.3 (status ↔ column) |
| `task_links` | quan hệ blocks/blocked_by/relates_to |
| `labels` + `task_labels` | nhãn (many-to-many) |
| `sprints` | (UI đã bỏ Sprints nhưng bảng còn — port tối thiểu hoặc skip) |
| `comments` + `comment_mentions` | bình luận + mention |
| `attachments` | file đính kèm task |
| `activity_logs` | audit log (action, entity_type, entity_id, old/new values JSON) |
| `notifications` | thông báo fan-out |
| `invites` | mời qua link (token, role, hết hạn 7 ngày) |
| `working_hours` | log giờ làm (cho reports) |

### 4.2. Map kiểu Postgres → MySQL (nếu đổi sang MySQL)
| Postgres hiện tại | MySQL / Laravel migration |
|---|---|
| `uuid` (PK) | `$table->uuid('id')->primary()` (CHAR(36)) — hoặc `ulid` |
| `enum` (vd `tasks_status_enum`) | `$table->enum('status', [...])` hoặc string + validate ở app |
| `timestamptz` | `timestamp` (lưu UTC, đổi múi giờ ở app/FE) |
| `text` | `text`/`longText` |
| `numeric(6,2)` (hours) | `decimal(6,2)` |
| `ILIKE` (search) | `LIKE` (MySQL không phân biệt hoa thường mặc định) |
| JSON (`new_values`) | `json` |
| `deleted_at` (soft delete) | dùng trait `SoftDeletes` của Laravel |

> Enum giữ **đúng giá trị** đang dùng để FE không vỡ:
> - status: `todo, in_progress, in_review, done`
> - priority: `urgent, high, medium, low, lowest`
> - type: `bug, feature, task, story, epic`
> - role: `admin, manager, member, viewer`

### 4.3. ⚠️ Quy tắc "Status = Column nguồn dữ liệu chính" (đặc thù dự án)
- `tasks.column_id` (động) là **nguồn sự thật**; `tasks.status` (enum 4 giá trị) được **suy ra từ tên column**.
- Phải port hàm `columnNameToStatus(name)` (xem `backend/src/modules/tasks/tasks.service.ts`):
  - chứa `done/complete/closed` → `done`
  - chứa `review/testing/qa` → `in_review`
  - chứa `progress/doing/active/wip` → `in_progress`
  - còn lại → `todo`
- Khi **update task có `columnId`** (hoặc khi **move**): set `column_id` + `position` + `status = columnNameToStatus(column.name)`.
- Màu column (`columns.color`) được FE tái dùng làm màu status badge — giữ nguyên.

---

## 5. Port từng module (kèm endpoint chính)

> Lấy danh sách route đầy đủ từ `backend/src/modules/**/*.controller.ts` và đối chiếu `frontend/src/api/*.ts`.

### 5.1. Auth (`/auth`) — `frontend/src/api/auth.ts`
| Method · Path | Việc |
|---|---|
| POST `/auth/register` | đăng ký công khai (→ pending) hoặc qua invite token (→ active). Trả `{status:'active'|'pending', ...}` |
| POST `/auth/login` | trả `{user, accessToken, refreshToken}` + set cookie refresh. Hỗ trợ `otp` (2FA) |
| POST `/auth/refresh` | đọc cookie → xoay vòng → `{accessToken}` |
| POST `/auth/logout` | revoke refresh + xoá cookie |
| GET `/auth/me` | user hiện tại |
| POST `/auth/password/forgot` · `/password/reset` | quên/đặt lại mật khẩu (email + `account_tokens`) |
| POST `/auth/email/verify` · `/email/resend` | xác thực email |
| GET `/auth/sessions` · DELETE `/auth/sessions/{id}` · DELETE `/auth/sessions` | quản lý refresh session (revoke) |
| POST `/auth/2fa/setup` · `/2fa/enable` · `/2fa/disable` | TOTP (xem mục 6) |
| GET `/auth/google` · `/auth/google/callback` | OAuth Google (dùng **Laravel Socialite**) |

> Đăng ký công khai → **pending**, admin duyệt mới đăng nhập được; invite link → **active** ngay. Login khi chưa active trả **403** (FE hiện 1 modal "chờ duyệt").

### 5.2. Users (`/users`) — `api/users.ts`
- Update profile, `PATCH /users/{id}/avatar` (upload), đổi mật khẩu, tạo user, list, xoá user, **export dữ liệu cá nhân (JSON)**, xoá tài khoản.
- Avatar lưu `storage/app/public/avatars`, trả URL tương đối `/uploads/avatars/...` (giữ nguyên format để FE không sửa) — hoặc đổi FE sang URL Laravel.

### 5.3. Projects (`/projects`) + Manage (`/manage/projects`) — `api/projects.ts`
- CRUD project, `get`, archive/restore, soft-delete (10s undo ở FE), **transfer ownership**, deadline.
- RBAC: tạo project cần quyền `create_project`; sửa/xoá cần `edit_project`/`delete_project`.

### 5.4. Members (`/projects/{id}/members`) — `api/members.ts`
- list, add (nhiều user), remove.

### 5.5. Columns (`/projects/{id}/columns`) — `api/columns.ts`
- list, create `{name, color?}`, update `{name?, color?, wipLimit?}`, delete (chặn nếu còn task), `PATCH .../reorder` `{columnIds: []}`.

### 5.6. Tasks (`/projects/{id}/tasks`) — `api/tasks.ts` (module lớn nhất)
| Method · Path | Việc |
|---|---|
| GET `/tasks` | list + **bộ lọc** (status, priority, type, assignee, label, sprint, due, created range, hours, search…) + **phân trang `meta`** |
| GET `/tasks/{id}` | chi tiết (kèm subtasks, parentTask, labels, links) |
| POST `/tasks` | tạo (`columnId, title, priority, type, assigneeId, dueDate…`) |
| PATCH `/tasks/{id}` | update — **hỗ trợ `columnId`** (move + suy ra status), `status`, `labelIds`… |
| DELETE `/tasks/{id}` · PATCH `/tasks/{id}/restore` | soft delete + undo |
| PATCH `/tasks/{id}/archive` · `/unarchive` | lưu trữ |
| PATCH `/tasks/{id}/move` | `{columnId, position}` (DnD) → set status theo column |
| POST `/tasks/{id}/log-time` | `{hours, loggedDate?, description?}` → cộng `logged_hours` |
| GET/POST/DELETE `/tasks/{id}/links` | task links |

> Logic position/reorder trong column phải port cẩn thận (xem `reorderWithinColumn`, `moveAcrossColumns`).

### 5.7. Comments (`/projects/{id}/tasks/{tid}/comments`) — `api/comments.ts`
- list, create (kèm parentId reply + mention), update, delete. Phát notification mention.

### 5.8. Attachments — `api/attachments.ts`
- POST upload (multipart, multer→Storage, giới hạn 25MB, lọc mimetype, tên `uuid.ext`).
- GET download (**có auth** — stream qua controller, không phải static).
- DELETE (chỉ chủ file).
- GET list toàn project (`project-attachments.controller`).

### 5.9. Labels (`/projects/{id}/labels`) — `api/labels.ts`
- list, create `{name, color}`. Many-to-many với task qua `task_labels`.

### 5.10. Roles & Permissions (`/roles`) — `api/roles.ts`
- list roles, create/update/delete role, cập nhật permission của role.
- Dùng **spatie/laravel-permission**; seed các permission hiện có (`create_project, edit_project, delete_project, assign_tasks, approve_task, update_own_task, view_all_projects, manage roles/users/reports`…). Lấy danh sách permission chính xác từ DB hiện tại (bảng roles/permissions) hoặc seed.

### 5.11. Reports (`/projects/{id}/reports`) — `api/reports.ts`
- `summary` (KPIs, donut status, workload, recent activity), `developer-report` (năng suất per-dev, productivity score, **taskDetails**), weekly/monthly…
- Nhiều **query phức tạp** (group by, aggregate, working_hours) → port sang **Query Builder/raw SQL** (giữ gần nguyên logic SQL). Lưu ý: developer report lọc `assignee IS NOT NULL` + `created_at BETWEEN from..to`.

### 5.12. Activity (`/projects/{id}/activity`) — `api/activity.ts`
- list (filter user/action/entity/range, phân trang), **export CSV**.
- Ghi log qua **model events / observers** (thay cho TypeORM subscriber): create/update/delete/move/comment/assign/status_changed.

### 5.13. Notifications — `api/notifications.ts`
- list, mark all read, unread count. Fan-out (Jira-like): task event → notify người liên quan + manager/admin + owner. Dùng **Laravel Notifications** (database channel) + đẩy realtime (mục 8).

### 5.14. Invites — `api/invites.ts`
- validate token, create invite (email + role, hết hạn 7 ngày, gửi link), revoke, list pending.

### 5.15. Archived — `api/archived.ts`
- list task/project đã lưu trữ, restore, xoá vĩnh viễn.

### 5.16. My Tasks (`/me/tasks`) — `api/myTasks.ts`
- list task cross-project liên quan user (assigned/reported/watching).

### 5.17. Export — module export
- Trigger export (CSV/PDF) chạy nền: **Laravel Queue Job** + lưu file `storage` + thông báo khi xong (notification `export_ready`). Thêm TTL/cleanup file export.

---

## 6. 2FA (TOTP) — port `backend/src/modules/auth/totp.ts`
- Chuẩn **TOTP RFC 6238**: secret base32, HMAC-SHA1, **6 số / 30 giây**, cửa sổ ±30s.
- Laravel: dùng package **`pragmarx/google2fa`** (hoặc port `totp.ts` thuần PHP — không khó).
- Secret **mã hoá** trước khi lưu (`Crypt::encryptString`), env key riêng.
- Flow: `setup` (tạo secret + trả `otpauth://` URI để FE render QR) → `enable` (xác minh mã) → login yêu cầu mã nếu bật.
- **Lưu ý**: UI 2FA hiện đang **tạm ẩn** ở FE (`SHOW_TWO_FACTOR=false` trong `AccountPage.tsx` + `LoginPage.tsx`) — port BE vẫn nên có sẵn, bật lại khi cần.

---

## 7. File storage / uploads
- `php artisan storage:link`.
- Avatars: public. Attachments: **private**, tải qua route có auth + policy (chỉ thành viên project).
- Giữ đường dẫn `/uploads/avatars/...`, `/uploads/attachments/...` (hoặc đổi FE). FE upload cần `Content-Type: multipart` — Laravel nhận `$request->file(...)`.
- Cân nhắc S3 nếu chạy nhiều instance.

---

## 8. Realtime: Socket.IO → Laravel Echo (phần khó nhất)

FE đang dùng `socket.io-client` (`frontend/src/hooks/useSocket.ts`) với token auth và các event:
`task:created`, `task:updated`, `task:moved`, `task:deleted` (+ có thể comment/notification).

**Laravel không nói được giao thức Socket.IO** → phải đổi sang Pusher-protocol:

1. **Server**: **Laravel Reverb** (self-host, miễn phí) hoặc **Pusher** (cloud). Phát event qua **Broadcasting**:
   ```php
   class TaskUpdated implements ShouldBroadcast {
       public function broadcastOn() { return new PrivateChannel("project.{$this->projectId}"); }
       public function broadcastAs() { return 'task:updated'; }
   }
   ```
2. **FE đổi** `socket.io-client` → **`laravel-echo` + `pusher-js`**:
   ```ts
   const echo = new Echo({ broadcaster: 'reverb', key, wsHost, wsPort, forceTLS, authEndpoint: '/api/v1/broadcasting/auth' })
   echo.private(`project.${projectId}`)
       .listen('.task:updated', (e) => { /* cập nhật cache như cũ */ })
   ```
3. Auth private channel: route `broadcasting/auth` + Sanctum.
4. Map đúng tên event để phần xử lý cache trong FE giữ nguyên.

> Đây là chỗ **bắt buộc sửa FE**. Nếu muốn FE 0 đổi: phải dựng 1 Socket.IO server riêng (Node) — nhưng vậy thì mất mục tiêu "bỏ Node".

---

## 9. Queue, Mail, Schedule, Monitoring
- **Queue**: export + email nặng → `php artisan queue:work` (Redis). Cần 1 worker chạy nền (supervisor).
- **Mail**: Mailable cho invite, reset password, verify email, notification. Cấu hình SMTP trong `.env`.
- **Schedule**: backup DB (`mysqldump`/`pg_dump`) đặt trong `app/Console/Kernel.php` `schedule()` thay cho service backup compose.
- **Sentry**: `sentry/sentry-laravel` (BE) — FE đã có sẵn `@sentry/react`.
- **Health**: route `/api/v1/health/live` + `/health/ready` (check DB + Redis) để giống hiện tại.

---

## 10. Thay đổi cần làm ở FE React (tối thiểu)
1. `.env`: `VITE_API_URL=https://.../api/v1` (+ `VITE_WS_*` cho Echo).
2. **Realtime**: thay `socket.io-client` → `laravel-echo` + `pusher-js` (sửa `hooks/useSocket.ts` + chỗ subscribe).
3. **Refresh token**: nếu Laravel dùng Sanctum cookie thuần, có thể đổi `client.ts` (bỏ Bearer, dùng cookie) — hoặc giữ access Bearer + refresh cookie như hiện tại (ít đổi nhất).
4. Kiểm tra mọi nơi đọc `response.data.data` / `response.data.message` vẫn khớp.
5. Đường dẫn file `/uploads/...` nếu đổi host.

> Mục tiêu: **không động vào UI/logic nghiệp vụ** của FE, chỉ tầng api + socket.

---

## 11. Lộ trình thực hiện (phased)
1. **Scaffold**: Laravel 11 + Sanctum + spatie/permission + migrations toàn bộ bảng (mục 4) + seeder (roles, permissions, admin/manager/member seed `@taskboard.dev`).
2. **Auth + RBAC** → test bằng chính React FE (login/refresh/me/logout).
3. **Projects + Members + Columns** → board hiển thị được.
4. **Tasks** (CRUD + move + filter + pagination) → DnD board chạy (chưa realtime).
5. **Comments + Attachments + Labels**.
6. **Reports + Activity + Notifications + My Tasks + Invites + Archived**.
7. **Export (queue)** + **Mail**.
8. **Realtime (Reverb + Echo)** + sửa FE socket.
9. **2FA + email verify + password reset + sessions** (bật lại UI khi cần).
10. **Hardening**: health, Sentry, rate limit (`throttle` middleware), CORS, backup schedule, CI.

---

## 12. Kiểm thử & nghiệm thu
- Với mỗi module: chạy **React FE hiện tại** trỏ vào Laravel → click thật, so sánh hành vi với bản NestJS.
- Viết **PHPUnit/Pest** cho service phức tạp (reports, move task, refresh rotation, invite).
- Checklist go-live: login + refresh, tạo/kéo task, realtime 2 tab, upload/download file, reports khớp số, email gửi được, queue export chạy.

---

## 13. Rủi ro / lưu ý
- **Realtime + FE socket** là phần đổi nhiều & dễ sai nhất → ưu tiên làm sớm 1 spike để chốt Reverb/Pusher.
- **Reports**: query nặng, dễ lệch số nếu port ẩu → đối chiếu từng con số với bản cũ.
- **Status ↔ Column**: nhớ giữ `columnNameToStatus` để badge/filter không lệch.
- **Soft delete + undo 10s**, **archive vs delete**, **refresh rotation (revoke token cũ)** — các hành vi tinh tế phải port đúng.
- **Phân trang `meta`** và **envelope `{success,data}`** sai là FE vỡ hàng loạt → làm 1 lớp chuẩn hoá response trước khi port module.
- Đây là **viết lại toàn bộ BE** (khối lượng lớn) — cân nhắc so với chỉ thuê 1 VPS chạy Node hiện có.

---

## 14. Tham chiếu nhanh (file gốc để đối chiếu khi port)
- Entities: `backend/src/modules/**/entities/*.entity.ts`
- Controllers (routes): `backend/src/modules/**/*.controller.ts`
- Logic quan trọng: `tasks.service.ts` (move/status), `auth.service.ts` (token rotation, 2FA, reset), `reports.service.ts` (query), `notifications.service.ts` (fan-out)
- Enums: `shared/src/enums.ts`
- API FE đang gọi: `frontend/src/api/*.ts`
- Auth/refresh FE: `frontend/src/api/client.ts`, `frontend/src/stores/useAuthStore.ts`
- Realtime FE: `frontend/src/hooks/useSocket.ts`
