<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'recipientId' => $this->recipient_id,
            'actorId' => $this->actor_id,
            'actor' => $this->actor ? [
                'id' => $this->actor->id,
                'fullName' => $this->actor->full_name,
                'avatarUrl' => $this->actor->avatar_url,
            ] : null,
            'type' => $this->type,
            'entityType' => $this->entity_type,
            'entityId' => $this->entity_id,
            'message' => $this->message,
            'readAt' => $this->read_at?->toIso8601String(),
            'createdAt' => $this->created_at?->toIso8601String(),
            'context' => $this->context_data ?? null,
        ];
    }
}
