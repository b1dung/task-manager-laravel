#!/bin/sh
set -eu

backup_dir="${BACKUP_DIR:-./backups}"
mkdir -p "$backup_dir"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
output="$backup_dir/taskboard-$timestamp.sql.gz"
temporary="$backup_dir/.taskboard-$timestamp.sql.tmp"
umask 077
trap 'rm -f "$temporary"' EXIT HUP INT TERM

: "${DB_HOST:?DB_HOST is required}"
: "${DB_DATABASE:?DB_DATABASE is required}"
: "${DB_USERNAME:?DB_USERNAME is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"

export MYSQL_PWD="$DB_PASSWORD"
mysqldump \
  --host="$DB_HOST" \
  --port="${DB_PORT:-3306}" \
  --user="$DB_USERNAME" \
  --single-transaction \
  --quick \
  --routines \
  --triggers \
  --no-tablespaces \
  --set-gtid-purged=OFF \
  --result-file="$temporary" \
  "$DB_DATABASE"
gzip -9 -c "$temporary" > "$output"
rm -f "$temporary"
sha256sum "$output" > "$output.sha256"
find "$backup_dir" -type f \( -name 'taskboard-*.sql.gz' -o -name 'taskboard-*.sql.gz.sha256' \) -mtime "+${BACKUP_RETENTION_DAYS:-30}" -delete
echo "$output"
