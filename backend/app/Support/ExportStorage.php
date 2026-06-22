<?php

namespace App\Support;

use App\Services\NotificationService;
use Illuminate\Support\Facades\Storage;

/**
 * Shared storage helpers for queued exports (Excel / PDF). Files live on the
 * `local` disk under `exports/` and expire after 24h, mirroring the NestJS
 * `EXPORT_DIR` + cleanup behaviour.
 */
class ExportStorage
{
    public const DISK = 'local';

    public const DIR = 'exports';

    private const TTL_SECONDS = 24 * 60 * 60;

    /** Absolute filesystem path for a stored export, creating the dir if needed. */
    public static function path(string $fileName): string
    {
        $disk = Storage::disk(self::DISK);
        if (! $disk->exists(self::DIR)) {
            $disk->makeDirectory(self::DIR);
        }

        return $disk->path(self::DIR.'/'.$fileName);
    }

    /** Delete export files older than the TTL. */
    public static function cleanupExpired(): void
    {
        $disk = Storage::disk(self::DISK);
        if (! $disk->exists(self::DIR)) {
            $disk->makeDirectory(self::DIR);

            return;
        }
        $cutoff = time() - self::TTL_SECONDS;
        foreach ($disk->files(self::DIR) as $file) {
            if ($disk->lastModified($file) < $cutoff) {
                $disk->delete($file);
            }
        }
    }

    /** Notify the requester that their export is ready, with the download link. */
    public static function notifyReady(
        NotificationService $notifications,
        string $projectId,
        string $recipientId,
        string $fileName,
        string $message,
    ): void {
        $fileUrl = "/api/v1/projects/{$projectId}/export/files/{$fileName}";
        $notifications->direct($recipientId, 'export_ready', 'export', $fileName, "{$message}: {$fileUrl}");
    }
}
