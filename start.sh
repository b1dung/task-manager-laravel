#!/usr/bin/env bash
#
# start.sh — bring the CRM Docker stack up correctly after a machine reboot.
#
# Why this exists: Docker Desktop on WSL2 does NOT re-sync the ./backend bind
# mount when containers auto-restart after a reboot, so /var/www/html mounts
# empty and every /api/* request 404s ("File not found" from php-fpm).
# Recreating the backend containers via `docker compose up` re-establishes the
# mount. (See .claude memory: docker-reboot-bind-mount-404.)
#
# Usage:
#   ./start.sh          # fix + start backend, then verify the login API
#   ./start.sh --fe     # also start the Vite FE dev server on :5174 (foreground)
#
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

echo "==> Waiting for Docker engine to be ready..."
for _ in $(seq 1 60); do
  if docker info >/dev/null 2>&1; then break; fi
  sleep 2
done
if ! docker info >/dev/null 2>&1; then
  echo "    ERROR: Docker engine not reachable after 120s. Is Docker Desktop running?" >&2
  exit 1
fi

echo "==> Recreating backend containers (re-syncs ./backend bind mount)..."
# NOTE: never run a bare `docker compose up -d` (no service list) — that re-runs
# the one-shot fe-build (npm ci as ROOT) and re-root-owns frontend/node_modules.
docker compose up -d --force-recreate app queue scheduler reverb

# Recreated app gets a NEW IP; nginx caches the old `app:9000` upstream → 502.
# `restart` (not `up`) re-resolves DNS without re-running the fe-build one-shot.
echo "==> Restarting nginx so it re-resolves the app container..."
docker compose restart web

echo "==> Waiting for login API on :8080 ..."
ok=0
code=000
for _ in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
    http://localhost:8080/api/v1/auth/login -H 'Accept: application/json' || true)
  case "$code" in
    422|401|429) echo "    OK — login API responding (HTTP $code)"; ok=1; break ;;
    *)           printf '\r    waiting... (HTTP %s)   ' "$code"; sleep 1 ;;
  esac
done
echo
if [ "$ok" -ne 1 ]; then
  echo "    WARNING: login API still unhealthy (last HTTP $code)." >&2
  echo "    Inspect:  docker compose logs --tail=50 app" >&2
fi

if [ "${1:-}" = "--fe" ]; then
  echo "==> Starting Vite FE dev server (:5174)..."
  if [ -x frontend/node_modules/.bin/vite ]; then
    ( cd frontend && npm run dev )
  else
    echo "    SKIP: frontend/node_modules missing/broken (vite not found)." >&2
    echo "    Fix once:  cd frontend && sudo rm -rf node_modules && npm install" >&2
  fi
fi

echo "==> Done. Backend: http://localhost:8080  ·  FE dev: http://localhost:5174"
