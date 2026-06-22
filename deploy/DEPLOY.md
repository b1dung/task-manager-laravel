# Deploy & Cutover — Laravel + React (Phase 12–13)

## A. Yêu cầu server
PHP 8.4 (pdo_mysql, gd, zip, bcmath, pcntl, intl, redis), Composer, MySQL 8, Redis, Node 20 (chỉ để build FE), Apache (mod_proxy_fcgi/wstunnel/rewrite/ssl). Hoặc dùng Docker theo `docker-compose.prod.yml` (đã gói sẵn tất cả).

## B. Build & deploy (Docker — đơn giản nhất)
```bash
# 1. Build React (API/WS cùng domain → đường dẫn tương đối)
cd frontend && VITE_API_URL=/api/v1 VITE_REVERB_HOST=app.example.com VITE_REVERB_PORT=443 \
  VITE_REVERB_SCHEME=https npm ci && npm run build && cd ..

# 2. Chuẩn bị laravel-backend/.env prod (APP_ENV=production, APP_DEBUG=false, APP_KEY,
#    DB_*, REDIS_*, FRONTEND_URL=https://app.example.com, SMTP_*, REVERB_*, SENTRY_LARAVEL_DSN,
#    DB_ROOT_PASSWORD). Sinh key: php artisan key:generate

# 3. Lên stack (mysql, redis, app php-fpm, migrate, queue, scheduler, reverb, apache)
docker compose -f deploy/docker-compose.prod.yml --env-file laravel-backend/.env up -d --build

# 4. Tối ưu cache + seed roles (lần đầu)
docker compose -f deploy/docker-compose.prod.yml exec app php artisan config:cache route:cache view:cache
docker compose -f deploy/docker-compose.prod.yml exec app php artisan db:seed --force   # roles + admin seed
```

## C. Deploy thẳng (không Docker)
- `composer install --no-dev -o`; `.env` prod; `php artisan migrate --force`; `config/route/view:cache`; `storage:link`.
- Tiến trình nền qua **supervisor** (`deploy/supervisor.conf`): queue worker, scheduler, reverb.
- Apache vhost: `deploy/apache-taskboard.conf` (sửa domain + chỉnh `fcgi://127.0.0.1:9000` nếu php-fpm local).
- SSL: `certbot --apache -d app.example.com`.

## D. Vận hành
- **Backup**: cron `mysqldump` hằng ngày + giữ `BACKUP_RETENTION_DAYS`. (Có thể thêm vào `routes/console.php` Schedule.)
- **Monitor**: Sentry (`SENTRY_LARAVEL_DSN`), uptime check `/api/v1/health/ready`.
- **Logs**: `docker compose ... logs -f app queue reverb`.

---

## E. Phase 9 — Migrate dữ liệu thật (chạy 1 lần, trên server có cả 2 DB)
```bash
PG_HOST=<pg> PG_DATABASE=taskboard PG_USERNAME=<u> PG_PASSWORD=<p> \
  php artisan migrate:from-postgres --fresh     # cần pdo_pgsql
# Copy file: cp -r <nest>/backend/uploads/* laravel-backend/storage/app/public/
# Verify: so số dòng từng bảng (psql count vs mysql count). Token cũ không chuyển → user login lại.
```

---

## F. Phase 13 — Cutover runbook
1. **Chuẩn bị**: deploy Laravel song song (domain tạm, vd `new.app...`), chạy `migrate:from-postgres` từ snapshot prod, smoke test toàn bộ (login, board, realtime 2 tab, upload, reports).
2. **Freeze**: thông báo bảo trì ngắn; tạm dừng ghi vào hệ NestJS cũ.
3. **Đồng bộ delta**: chạy lại `migrate:from-postgres --fresh` để lấy dữ liệu mới nhất.
4. **Chuyển DNS/Apache**: trỏ domain chính sang Laravel; build FE với domain thật; deploy FE.
5. **Verify prod**: login, tạo/kéo task, realtime, upload, notifications, reports — checklist mục G.
6. **Theo dõi 24–48h**: Sentry + logs; chuẩn bị **rollback** (trỏ DNS về NestJS cũ — giữ NestJS chạy tới khi yên tâm).
7. **Decommission**: sau khi ổn định, tắt NestJS (`backend/`) + Postgres/Redis cũ; xoá `CONVERT-PROJECT-TO-LARAVEL.md`/`UPDATE-TODO.md`; cập nhật `CLAUDE.md` (stack mới); gỡ `spatie/laravel-permission` nếu không dùng.

## G. Checklist nghiệm thu go-live
- [ ] Login + refresh token (cookie) + logout
- [ ] Tạo project → 4 column mặc định; tạo/sửa/kéo task; status đổi theo column
- [ ] Realtime: mở 2 tab, kéo task → tab kia cập nhật (Reverb)
- [ ] Upload/tải attachment; avatar hiển thị
- [ ] Comments + mentions; labels; task links
- [ ] Reports (summary + developer) ra số đúng; Activity log; Notifications
- [ ] Invites (gửi mail), password reset, email verify, 2FA (bật `SHOW_TWO_FACTOR=true`)
- [ ] RBAC: tài khoản member KHÔNG tạo được project (403)
- [ ] queue worker + scheduler + reverb đang chạy; backup chạy; Sentry nhận event test
