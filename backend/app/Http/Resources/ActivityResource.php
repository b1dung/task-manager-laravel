<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ActivityResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'projectId' => $this->project_id,
            'userId' => $this->user_id,
            'user' => $this->whenLoaded('user', fn () => $this->user ? new TaskUserResource($this->user) : null),
            'action' => $this->action,
            'entityType' => $this->entity_type,
            'entityId' => $this->entity_id,
            'oldValues' => $this->old_values_json,
            'newValues' => $this->new_values_json,
            'createdAt' => $this->created_at?->toIso8601String(),
        ];
    }
}
