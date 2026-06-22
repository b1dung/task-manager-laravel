<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\ProjectMember;
use App\Models\User;
use Illuminate\Support\Str;

class NotificationService
{
    public function taskEvent(string $projectId, ?string $actorId, string $type, string $entityType, string $entityId, string $message, array $directRecipientIds = [], array $excludedIds = [], bool $includeManagers = true): void
    {
        $ids = collect($directRecipientIds)->filter();
        if ($includeManagers) {
            $ids = $ids->merge(ProjectMember::where('project_id', $projectId)->whereIn('role', ['admin', 'manager'])->pluck('user_id'));
        }
        $ids = $ids->merge(User::where('is_active', true)->whereHas('assignedRole', fn ($q) => $q->where('key', 'owner'))->pluck('id'))
            ->unique()->reject(fn ($id) => $id === $actorId || in_array($id, $excludedIds, true));
        $activeIds = User::where('is_active', true)->whereIn('id', $ids)->pluck('id');
        $now = now();
        $rows = $activeIds->map(fn ($id) => [
            'id' => (string) Str::uuid(),
            'recipient_id' => $id,
            'actor_id' => $actorId,
            'type' => $type,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'message' => $message,
            'read_at' => null,
            'created_at' => $now,
        ])->all();
        if ($rows) {
            Notification::insert($rows);
        }
    }

    /** Create a single notification for one recipient (no fan-out). */
    public function direct(string $recipientId, string $type, string $entityType, string $entityId, string $message): void
    {
        Notification::insert([
            'id' => (string) Str::uuid(),
            'recipient_id' => $recipientId,
            'actor_id' => null,
            'type' => $type,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'message' => $message,
            'read_at' => null,
            'created_at' => now(),
        ]);
    }
}
