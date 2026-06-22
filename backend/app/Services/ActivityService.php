<?php

namespace App\Services;

use App\Models\ActivityLog;
use Illuminate\Http\Request;

class ActivityService
{
    public function record(Request $request, string $projectId, string $action, string $entityType, string $entityId, ?array $old = null, ?array $new = null): ActivityLog
    {
        return ActivityLog::create([
            'project_id' => $projectId,
            'user_id' => $request->user()?->id,
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'old_values_json' => $old,
            'new_values_json' => $new,
            'ip_address' => $request->ip(),
        ]);
    }
}
