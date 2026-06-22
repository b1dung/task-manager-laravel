# CRM ComCom — Laravel edition

Standalone project: **Laravel API (`backend/`) + React FE (`frontend/`) + shared types (`shared/`)**.
Split from the original NestJS project (`../crm-comcom`); the FE is wired to Laravel
(REST via Vite proxy `/api` → `:8000`, realtime via Laravel Echo + Reverb).

## Ports (chạy song song được với project NestJS)

| Service | Port |
|---|---|
| Laravel API | 8000 |
| Frontend (Vite) | **5174** |
| Reverb (realtime) | 8080 |

## Chạy FULL stack trong Docker (MySQL + Redis + Reverb + Queue + Nginx) ⭐

Mọi thứ chạy trong container, 1 lệnh, truy cập 1 cổng duy nhất:

```bash
docker compose up -d --build      # build image PHP + build React + mysql/redis/reverb/queue
# → http://localhost:8080         (admin@taskboard.dev / password123)
```

| Service | Trong stack |
|---|---|
| `web` (nginx) | Cổng vào **:8080** — serve React build + proxy `/api` → php-fpm + `/app` (Reverb WS) |
| `app` | Laravel php-fpm (pdo_mysql, gd, redis, upload 250MB) |
| `mysql` / `redis` | DB + cache/queue (mysql cũng expose `:3307`) |
| `reverb` | Realtime websocket |
| `queue` / `scheduler` | Worker export + cron |
| `migrate` / `fe-build` | one-shot: migrate+seed / build React |

Dừng: `docker compose down`  ·  Xoá sạch DB: `docker compose down -v`.

## Chạy dev nhẹ (Docker, SQLite, chỉ API — không cần MySQL)

```bash
cd backend
docker compose -f docker-compose.dev.yml up -d   # API :8000, migrate + seed tự chạy (SQLite)

cd ../frontend
npm install
npm run dev                                       # FE :5174  → http://localhost:5174
```

Đăng nhập seed: `admin@taskboard.dev` / `password123`.

## Chạy dev — PHP/MySQL thật (server có PHP 8.4 + pdo_mysql)

```bash
cd backend
cp .env.example .env        # chỉnh DB_* sang MySQL
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve            # :8000
php artisan reverb:start     # realtime (terminal khác)

cd ../frontend && npm install && npm run dev
```

## Cấu trúc

```
crm-comcom-laravel/
├── backend/    Laravel 13 API (Sanctum + RBAC + Reverb)
├── frontend/   React 19 + Vite (Laravel Echo)
├── shared/     @taskboard/shared (enums/types)
└── deploy/     Dockerfile prod, apache vhost, supervisor, DEPLOY.md
```

> Bản convert chi tiết: `CONVERT-PROJECT-TO-LARAVEL.md` · tiến độ: `UPDATE-TODO.md`.
# task-manager-laravel
