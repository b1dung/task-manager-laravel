<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MemberResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'projectId' => $this->project_id,
            'userId' => $this->user_id,
            'role' => $this->role,
            'joinedAt' => $this->joined_at?->toIso8601String(),
            'user' => new TaskUserResource($this->whenLoaded('user')),
            'taskCount' => (int) ($this->task_count ?? 0),
        ];
    }
}
