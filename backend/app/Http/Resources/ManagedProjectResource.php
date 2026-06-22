<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ManagedProjectResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'slug' => $this->slug,
            'description' => $this->description,
            'ownerId' => $this->owner_id,
            'createdAt' => $this->created_at?->toIso8601String(),
            'deadline' => $this->deadline?->toIso8601String(),
            'archivedAt' => $this->archived_at?->toIso8601String(),
            'taskCount' => (int) ($this->tasks_count ?? 0),
            'memberCount' => (int) ($this->members_count ?? 0),
            'owner' => $this->owner ? [
                'id' => $this->owner->id,
                'fullName' => $this->owner->full_name,
                'avatarUrl' => $this->owner->avatar_url,
            ] : null,
        ];
    }
}
