<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Phase 9 — copy existing data from the old NestJS PostgreSQL DB into MySQL.
 * UUID ids are preserved so all relations stay intact.
 *
 * Run ON THE SERVER (where both DBs are reachable):
 *   PG_HOST=... PG_DATABASE=taskboard PG_USERNAME=... PG_PASSWORD=... \
 *   php artisan migrate:from-postgres --fresh
 *
 * Requires the `pdo_pgsql` PHP extension on the box running it.
 */
class MigrateFromPostgres extends Command
{
    protected $signature = 'migrate:from-postgres {--fresh : truncate MySQL tables first}';
    protected $description = 'Copy data from the legacy PostgreSQL DB into MySQL (Phase 9)';

    // Dependency order. refresh_tokens/sessions/cache/jobs intentionally skipped
    // (tokens incompatible → users re-login). personal_access_tokens skipped too.
    private const TABLES = [
        'roles', 'users', 'projects', 'project_members', 'project_task_counters',
        'columns', 'sprints', 'labels', 'tasks', 'task_links', 'task_labels',
        'comments', 'comment_mentions', 'attachments', 'working_hours',
        'activity_logs', 'notifications', 'invites', 'account_tokens',
    ];

    public function handle(): int
    {
        config(['database.connections.pg_src' => [
            'driver' => 'pgsql',
            'host' => env('PG_HOST', '127.0.0.1'),
            'port' => env('PG_PORT', 5432),
            'database' => env('PG_DATABASE', 'taskboard'),
            'username' => env('PG_USERNAME', 'taskboard'),
            'password' => env('PG_PASSWORD', 'taskboard'),
            'charset' => 'utf8',
            'schema' => 'public',
        ]]);

        $pg = DB::connection('pg_src');
        $this->info('Connected to PostgreSQL source.');

        DB::statement('SET FOREIGN_KEY_CHECKS=0');
        try {
            foreach (self::TABLES as $table) {
                if ($this->option('fresh')) {
                    DB::table($table)->truncate();
                }
                $count = 0;
                $pg->table($table)->orderBy(1)->chunk(500, function ($rows) use ($table, &$count) {
                    $batch = array_map(fn ($r) => $this->normalize((array) $r), $rows->all());
                    DB::table($table)->insert($batch);
                    $count += count($batch);
                });
                $this->line(sprintf('  %-22s %d rows', $table, $count));
            }
        } finally {
            DB::statement('SET FOREIGN_KEY_CHECKS=1');
        }

        $this->info('Done. Verify counts, copy uploads/, then have users log in again.');

        return self::SUCCESS;
    }

    /** Normalize Postgres row values for MySQL (bool, timestamptz suffix, json). */
    private function normalize(array $row): array
    {
        foreach ($row as $k => $v) {
            if (is_bool($v)) {
                $row[$k] = $v ? 1 : 0;
            } elseif (is_string($v) && preg_match('/^\d{4}-\d\d-\d\d[ T]\d\d:\d\d/', $v)) {
                // Only datetime-looking strings: drop tz offset ("...+00") for MySQL datetime.
                $row[$k] = preg_replace('/([+-]\d{2}(:?\d{2})?)$/', '', rtrim($v));
            }
        }

        return $row;
    }
}
