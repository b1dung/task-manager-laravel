#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
f="taskboard-dump-$(date +%Y%m%d-%H%M%S).sql"
docker exec crm-camcom-laravel-mysql-1 \
  mysqldump -u root -proot \
  --single-transaction --no-tablespaces --routines --triggers \
  taskboard > "$f"
echo "WROTE $f"
ls -lh "$f"
