# Backend env for the full Docker stack (docker-compose.yml).
# Mounted/loaded into every PHP service (app/migrate/queue/reverb/scheduler).
APP_NAME=TaskBoard
APP_ENV=local
APP_KEY=base64:1zUg9TiCfpWu83SSVKdoifB392fsS9tRuozriOADqBA=
APP_DEBUG=true
APP_URL=http://localhost:8080
FRONTEND_URL=http://localhost:8080

LOG_CHANNEL=stderr
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=taskboard
DB_USERNAME=taskboard
DB_PASSWORD=taskboard

# Stateless API (Bearer tokens) → array session avoids needing a sessions table.
SESSION_DRIVER=array
CACHE_STORE=redis
QUEUE_CONNECTION=redis
REDIS_CLIENT=phpredis
REDIS_HOST=redis
REDIS_PORT=6379

BROADCAST_CONNECTION=reverb
REVERB_APP_ID=953266
REVERB_APP_KEY=ytubefcrdytfrvlnl3fe
REVERB_APP_SECRET=jhtrsfhxrbnc9dnf7thg
# App publishes to the reverb service; server binds all interfaces.
REVERB_HOST=reverb
REVERB_PORT=8080
REVERB_SCHEME=http
REVERB_SERVER_HOST=0.0.0.0
REVERB_SERVER_PORT=8080

MAIL_MAILER=log
