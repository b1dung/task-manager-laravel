<?php

use App\Models\Role;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        // Grant the new `manage_settings` permission to owner & admin roles.
        Role::whereIn('key', ['owner', 'admin'])->get()->each(function (Role $role) {
            $perms = $role->permissions ?? [];
            if (! in_array('manage_settings', $perms, true)) {
                $perms[] = 'manage_settings';
                $role->permissions = $perms;
                $role->save();
            }
        });
    }

    public function down(): void
    {
        Role::whereIn('key', ['owner', 'admin'])->get()->each(function (Role $role) {
            $role->permissions = array_values(array_filter(
                $role->permissions ?? [],
                fn ($p) => $p !== 'manage_settings',
            ));
            $role->save();
        });
    }
};
