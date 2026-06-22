<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ManagedMemberResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'userId' => $this->user_id,
            'role' => $this->role,
            'joinedAt' => $this->joined_at?->toIso8601String(),
            'user' => $this->user ? [
                'id' => $this->user->id,
                'fullName' => $this->user->full_name,
                'email' => $this->user->email,
                'avatarUrl' => $this->user->avatar_url,
            ] : null,
        ];
    }
}
