<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ── System roles (ported from the existing NestJS roles table) ──────────
        $roles = [
            ['key' => 'owner', 'name' => 'Owner', 'sort_order' => 0, 'permissions' => [
                'manage_users', 'manage_roles', 'create_project', 'edit_project', 'delete_project',
                'create_sprint', 'assign_tasks', 'create_task', 'update_own_task', 'approve_task',
                'view_reports', 'billing_access', 'invite_client', 'view_pages', 'view_all_projects',
            ]],
            ['key' => 'admin', 'name' => 'Admin', 'sort_order' => 1, 'permissions' => [
                'manage_users', 'manage_roles', 'create_project', 'edit_project', 'delete_project',
                'create_sprint', 'assign_tasks', 'create_task', 'update_own_task', 'approve_task',
                'view_reports', 'invite_client', 'view_pages',
            ]],
            ['key' => 'pm', 'name' => 'PM', 'sort_order' => 2, 'permissions' => [
                'create_project', 'edit_project', 'create_sprint', 'assign_tasks', 'create_task',
                'update_own_task', 'approve_task', 'view_reports', 'invite_client', 'view_pages',
            ]],
            ['key' => 'team_lead', 'name' => 'Team Lead', 'sort_order' => 3, 'permissions' => [
                'edit_project', 'create_sprint', 'assign_tasks', 'create_task', 'update_own_task',
                'approve_task', 'view_reports', 'view_pages',
            ]],
            ['key' => 'member', 'name' => 'Member', 'sort_order' => 4, 'permissions' => [
                'create_task', 'update_own_task', 'view_reports', 'view_pages',
            ]],
            ['key' => 'client', 'name' => 'Client', 'sort_order' => 5, 'permissions' => [
                'view_reports', 'view_pages',
            ]],
        ];

        foreach ($roles as $r) {
            Role::updateOrCreate(
                ['key' => $r['key']],
                ['name' => $r['name'], 'is_system' => true, 'sort_order' => $r['sort_order'], 'permissions' => $r['permissions']],
            );
        }

        $adminRole = Role::where('key', 'admin')->first();

        $users = [
            ['email' => 'b1dung@gmail.com', 'full_name' => 'Bui Manh Dung', 'role' => 'owner', 'role_id' => $adminRole?->id],
        ];

        foreach ($users as $u) {
            User::updateOrCreate(
                ['email' => $u['email']],
                [
                    'password_hash' => Hash::make('@admin123'),
                    'full_name' => $u['full_name'],
                    'role' => $u['role'],
                    'role_id' => $u['role_id'],
                    'is_active' => true,
                    'language' => 'en',
                    'appearance' => 'light',
                    'timezone' => 'Asia/Ho_Chi_Minh',
                    'email_verified_at' => now(),
                    'two_factor_enabled' => false,
                ],
            );
        }
    }
}
