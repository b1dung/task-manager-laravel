<?php

namespace App\Support;

/**
 * Static catalog of all permissions the workspace supports (ported from the
 * NestJS `permissions.catalog.ts`). Roles store a subset of these keys in their
 * `permissions` column; the frontend renders the permission matrix from
 * GET /permissions.
 */
class PermissionCatalog
{
    /** @return array<int, array{key:string,label:string,category:string,description:string}> */
    public static function all(): array
    {
        return [
            // User management
            ['key' => 'manage_users', 'label' => 'Manage Users', 'category' => 'User Management', 'description' => 'Tạo, sửa, vô hiệu hóa tài khoản người dùng'],
            ['key' => 'manage_roles', 'label' => 'Manage Roles', 'category' => 'User Management', 'description' => 'Tạo role và phân quyền (truy cập trang này)'],
            ['key' => 'manage_settings', 'label' => 'Manage Settings', 'category' => 'User Management', 'description' => 'Xem và sửa cấu hình chung của site (timezone…)'],
            // Projects
            ['key' => 'view_all_projects', 'label' => 'View All Projects', 'category' => 'Projects', 'description' => 'Xem và truy cập MỌI dự án, kể cả dự án chưa được thêm vào team (super quyền)'],
            ['key' => 'create_project', 'label' => 'Create Project', 'category' => 'Projects', 'description' => 'Tạo dự án mới'],
            ['key' => 'edit_project', 'label' => 'Edit Project', 'category' => 'Projects', 'description' => 'Chỉnh sửa thông tin dự án'],
            ['key' => 'delete_project', 'label' => 'Delete Project', 'category' => 'Projects', 'description' => 'Xóa dự án'],
            // Sprints & tasks
            ['key' => 'create_sprint', 'label' => 'Create Sprint', 'category' => 'Sprints & Tasks', 'description' => 'Tạo và quản lý sprint'],
            ['key' => 'assign_tasks', 'label' => 'Assign Tasks', 'category' => 'Sprints & Tasks', 'description' => 'Gán task cho thành viên'],
            ['key' => 'create_task', 'label' => 'Create Task', 'category' => 'Sprints & Tasks', 'description' => 'Tạo task mới'],
            ['key' => 'update_own_task', 'label' => 'Update Own Task', 'category' => 'Sprints & Tasks', 'description' => 'Cập nhật trạng thái task của mình'],
            ['key' => 'approve_task', 'label' => 'Approve Task', 'category' => 'Sprints & Tasks', 'description' => 'Duyệt / approve task'],
            // Reports & billing
            ['key' => 'view_reports', 'label' => 'View Reports', 'category' => 'Reports & Billing', 'description' => 'Xem báo cáo và thống kê'],
            ['key' => 'billing_access', 'label' => 'Billing Access', 'category' => 'Reports & Billing', 'description' => 'Quản lý gói dịch vụ và thanh toán'],
            // General
            ['key' => 'invite_client', 'label' => 'Invite Client', 'category' => 'General', 'description' => 'Mời khách (client) vào dự án'],
            ['key' => 'view_pages', 'label' => 'View Page', 'category' => 'General', 'description' => 'Quyền xem các trang được chia sẻ'],
        ];
    }

    /** @return string[] valid permission keys */
    public static function keys(): array
    {
        return array_column(self::all(), 'key');
    }
}
