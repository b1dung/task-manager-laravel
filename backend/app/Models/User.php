<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasUuids, Notifiable;

    protected $keyType = 'string';

    public $incrementing = false;

    // The legacy schema keeps only created_at (no updated_at) on users.
    public $timestamps = false;

    protected $fillable = [
        'email', 'password_hash', 'full_name', 'avatar_url', 'role', 'is_active',
        'role_id', 'language', 'appearance', 'timezone', 'email_verified_at',
        'two_factor_enabled', 'two_factor_secret',
    ];

    protected $hidden = ['password_hash', 'two_factor_secret'];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'two_factor_enabled' => 'boolean',
            'email_verified_at' => 'datetime',
            'created_at' => 'datetime',
        ];
    }

    /** Auth uses the password_hash column instead of the default `password`. */
    public function getAuthPassword(): string
    {
        return $this->password_hash;
    }

    // Named assignedRole (not role) because the `role` enum column would
    // otherwise shadow the relationship accessor.
    public function assignedRole(): BelongsTo
    {
        return $this->belongsTo(Role::class, 'role_id');
    }

    public function projectMemberships(): HasMany
    {
        return $this->hasMany(ProjectMember::class);
    }

    public function ownedProjects(): HasMany
    {
        return $this->hasMany(Project::class, 'owner_id');
    }

    /** Effective permission keys, resolved from the assigned role. */
    public function permissions(): array
    {
        return $this->assignedRole?->permissions ?? [];
    }

    public function hasPermission(string $key): bool
    {
        return in_array($key, $this->permissions(), true);
    }

    /** Shape consumed by the React frontend (AuthUser). */
    public function toAuthArray(): array
    {
        return [
            'id' => $this->id,
            'email' => $this->email,
            'fullName' => $this->full_name,
            'avatarUrl' => $this->avatar_url,
            'role' => $this->role,
            'language' => $this->language,
            'appearance' => $this->appearance,
            'timezone' => $this->timezone,
            'twoFactorEnabled' => (bool) $this->two_factor_enabled,
        ];
    }
}
