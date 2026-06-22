<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AppUserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'fullName' => $this->full_name,
            'email' => $this->email,
            'avatarUrl' => $this->avatar_url,
            'role' => $this->role,
            'roleId' => $this->role_id,
            'isActive' => (bool) $this->is_active,
            'createdAt' => $this->created_at?->toIso8601String(),
            'language' => $this->language,
            'appearance' => $this->appearance,
            'timezone' => $this->timezone,
        ];
    }
}
