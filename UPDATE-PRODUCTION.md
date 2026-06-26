# Go-live production — task.mintoku.vn

Hướng dẫn + thông tin cấu hình để đưa code lên production. Realtime production dùng
**Pusher cloud** (không cần Reverb/wss proxy).

## 1. Thông tin môi trường

| | Giá trị |
|---|---|
| Domain | https://task.mintoku.vn |
| DB host / name / user | `localhost` / `mintoku_task` / `mintoku_task` |
| DB password | `AergVEWA83v6XxJwyMde` |
| SMTP server | `mail.task.mintoku.vn` port **587** (STARTTLS) |
| SMTP user / pass | `admin@task.mintoku.vn` / `WqRprCZEErLyM5CMwHz4` |
| Pusher App ID / Key | `2170601` / `ee583f9a9e7bdf6211e1` |
| Pusher Secret | `a6309ccbd8d4890dc321` |
| Pusher Cluster | `ap1` ⚠ **kiểm tra lại trong Pusher dashboard → App Keys** (sai cluster = mất realtime) |

## 2. `.env` production (dán vào `backend/.env` trên server)

> Template sạch (placeholder) ở `backend/.env.production.example`. Bản dưới đã điền sẵn secret thật.
> Sau khi dán: chạy `php artisan key:generate` để có `APP_KEY`.

```env
APP_NAME=Taskboard
APP_ENV=production
APP_KEY=                                 # chạy: php artisan key:generate
APP_DEBUG=false
APP_URL=https://task.mintoku.vn
FRONTEND_URL=https://task.mintoku.vn
APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

LOG_CHANNEL=stack
LOG_STACK=single
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=mintoku_task
DB_USERNAME=mintoku_task
DB_PASSWORD=AergVEWA83v6XxJwyMde

SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_SECURE_COOKIE=true
SESSION_DOMAIN=task.mintoku.vn
CACHE_STORE=database
QUEUE_CONNECTION=sync
FILESYSTEM_DISK=local

BROADCAST_CONNECTION=pusher
PUSHER_APP_ID=2170601
PUSHER_APP_KEY=ee583f9a9e7bdf6211e1
PUSHER_APP_SECRET=a6309ccbd8d4890dc321
PUSHER_APP_CLUSTER=ap1

MAIL_MAILER=smtp
MAIL_SCHEME=smtp
MAIL_HOST=mail.task.mintoku.vn
MAIL_PORT=587
MAIL_USERNAME=admin@task.mintoku.vn
MAIL_PASSWORD=WqRprCZEErLyM5CMwHz4
MAIL_FROM_ADDRESS="admin@task.mintoku.vn"
MAIL_FROM_NAME="${APP_NAME}"
```

## 3. Build frontend cho production (Pusher)

API là đường dẫn tương đối `/api/v1` nên không phụ thuộc domain; chỉ cần bake key Pusher.
Pusher cloud tự lo host theo cluster → **không cần** VITE_REVERB_* / wss proxy.

```bash
cd frontend
VITE_API_URL=/api/v1 \
VITE_BROADCASTER=pusher \
VITE_PUSHER_APP_KEY=ee583f9a9e7bdf6211e1 \
VITE_PUSHER_CLUSTER=ap1 \
npm ci && npm run build
```

→ Upload toàn bộ `frontend/dist/` lên web root của domain.
(`VITE_PUSHER_APP_KEY` + `VITE_PUSHER_CLUSTER` phải **khớp** `PUSHER_APP_KEY` + `PUSHER_APP_CLUSTER` ở `.env`.)

## 4. Các bước deploy backend

1. Upload + giải nén zip backend (xoá `vendor/` cũ trước khi giải nén để thay sạch).
   - **File/avatar user lưu ở `storage/app/uploads/{attachments,avatars}`** (disk `uploads`). Zip chỉ kèm **cấu trúc thư mục** (`.gitignore`), **không kèm file** → giải nén bản update **không bao giờ ghi đè** file đã upload. ⚠ **Tuyệt đối đừng xoá cả `storage/`** khi update (sẽ mất uploads + `.env`). `chmod -R 775 storage` để ghi được.
2. Tạo `backend/.env` từ mục 2 ở trên → `php artisan key:generate`.
3. Quyền ghi: `chmod -R 775 storage bootstrap/cache` (đúng owner web).
4. Import DB (file `.sql`) vào `mintoku_task`, hoặc chạy `php artisan migrate --force` nếu DB trống.
5. Tối ưu cache production:
   `php artisan config:cache && php artisan route:cache && php artisan view:cache`
   (đổi `.env` sau này thì chạy lại `php artisan config:clear`).
6. `php artisan storage:link` (nếu chưa có symlink public/storage).

## 5. Realtime (Pusher) — không cần worker/proxy
- Event dùng `ShouldBroadcastNow` → publish thẳng lên Pusher trong request. **Không cần** queue worker hay Reverb.
- Chỉ cần `.env` Pusher đúng + FE build đúng key/cluster.
- Verify: mở 2 tab cùng project (`/tasks` + `/reports`), thao tác bên này → bên kia tự cập nhật. DevTools → Network → WS thấy kết nối tới `ws-<cluster>.pusher.com` (101).

## 6. Email — đã có gửi lời mời tự động (mới)
- `InviteController::create` giờ **tự gửi email** chứa link đăng ký tới người được mời (ngoài việc vẫn trả link cho admin copy). FE hiện trạng thái "đã gửi email" / "không gửi được — copy link".
- Reset password + verify email: đã có sẵn (dùng chung `MailService`).
- Điều kiện: `.env` mục `MAIL_*` đúng (đã điền SMTP mintoku). Test nhanh sau deploy:
  `php artisan tinker --execute 'app(App\Services\MailService::class)->send("ban@example.com","Test","Hello from production");'`

## 7. Checklist go-live
- [ ] `.env` đã điền + `php artisan key:generate` (APP_KEY có giá trị)
- [ ] DB kết nối OK (`php artisan migrate:status`)
- [ ] `config:cache`/`route:cache`/`view:cache` đã chạy
- [ ] `frontend/dist` build với Pusher key/cluster đúng, đã upload
- [ ] Pusher **cluster** xác nhận đúng từ dashboard
- [ ] Test gửi mail (tinker) nhận được thật
- [ ] Realtime: 2 tab đồng bộ; WS tới `ws-<cluster>.pusher.com` = 101
- [ ] `APP_DEBUG=false`, `SESSION_SECURE_COOKIE=true`, HTTPS hoạt động
- [ ] `storage/` + `bootstrap/cache/` writable; `public/index.php` là bản sạch
