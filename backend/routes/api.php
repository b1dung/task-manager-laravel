<?php

use App\Http\Controllers\ActivityController;
use App\Http\Controllers\ArchivedController;
use App\Http\Controllers\AttachmentController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ColumnController;
use App\Http\Controllers\CommentController;
use App\Http\Controllers\ExportController;
use App\Http\Controllers\InviteController;
use App\Http\Controllers\LabelController;
use App\Http\Controllers\ManageProjectController;
use App\Http\Controllers\MemberController;
use App\Http\Controllers\MyTasksController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\ProjectController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\RolesController;
use App\Http\Controllers\SprintController;
use App\Http\Controllers\TaskController;
use App\Http\Controllers\TaskLinkController;
use App\Http\Controllers\UsersController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Route;

Route::post('broadcasting/auth', fn (Request $request) => Broadcast::auth($request))
    ->middleware('auth:sanctum');

// Health probes (mirror the NestJS /health/live and /health/ready endpoints).
Route::get('/health/live', fn () => response()->json(['status' => 'ok']));

Route::get('/health/ready', function () {
    try {
        DB::connection()->getPdo();
        Redis::connection()->ping();

        return response()->json(['status' => 'ok']);
    } catch (Throwable $e) {
        return response()->json(['status' => 'unavailable'], 503);
    }
});

// ── Auth ────────────────────────────────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register'])->middleware('throttle:5,1');
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('refresh', [AuthController::class, 'refresh'])->middleware('throttle:30,1');
    Route::post('password/forgot', [AuthController::class, 'forgotPassword'])->middleware('throttle:5,1');
    Route::post('password/reset', [AuthController::class, 'resetPassword'])->middleware('throttle:5,1');
    Route::post('email/verify', [AuthController::class, 'verifyEmail'])->middleware('throttle:10,1');
    Route::get('google', [AuthController::class, 'googleRedirect'])->middleware('throttle:20,1');
    Route::get('google/callback', [AuthController::class, 'googleCallback'])->middleware('throttle:20,1');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);
        Route::post('email/resend', [AuthController::class, 'resendVerification'])->middleware('throttle:5,1');
        Route::get('sessions', [AuthController::class, 'sessions']);
        Route::delete('sessions/{id}', [AuthController::class, 'revokeSession']);
        Route::delete('sessions', [AuthController::class, 'revokeAllSessions']);
        Route::post('2fa/setup', [AuthController::class, 'setupTwoFactor']);
        Route::post('2fa/enable', [AuthController::class, 'enableTwoFactor'])->middleware('throttle:10,1');
        Route::post('2fa/disable', [AuthController::class, 'disableTwoFactor'])->middleware('throttle:10,1');
    });
});

Route::get('invites/validate', [InviteController::class, 'validateToken'])->middleware('throttle:20,1');

Route::middleware('auth:sanctum')->group(function () {
    Route::post('invites', [InviteController::class, 'create'])->middleware('permission:manage_users');
    Route::get('invites', [InviteController::class, 'index'])->middleware('permission:manage_users');
    Route::delete('invites/{id}', [InviteController::class, 'revoke'])->middleware('permission:manage_users');
    Route::get('me/permissions', [AuthController::class, 'permissions']);
    Route::get('me/tasks', [MyTasksController::class, 'index']);

    // ── Roles & Permissions (RBAC management) ──
    Route::get('permissions', [RolesController::class, 'permissions'])->middleware('permission:manage_roles,manage_users');
    Route::get('roles', [RolesController::class, 'index'])->middleware('permission:manage_roles,manage_users');
    Route::post('roles', [RolesController::class, 'store'])->middleware('permission:manage_roles');
    Route::patch('roles/{id}', [RolesController::class, 'update'])->middleware('permission:manage_roles');
    Route::delete('roles/{id}', [RolesController::class, 'destroy'])->middleware('permission:manage_roles');

    // ── Notifications ──
    Route::get('notifications', [NotificationController::class, 'index']);
    Route::get('notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::patch('notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::patch('notifications/{id}/read', [NotificationController::class, 'markRead']);

    // ── Users ──
    Route::get('users', [UsersController::class, 'index']);
    Route::post('users', [UsersController::class, 'store'])->middleware('permission:manage_users');
    Route::get('users/me/export', [UsersController::class, 'exportOwnData']);
    Route::delete('users/me', [UsersController::class, 'deleteOwnAccount']);
    Route::get('users/{id}', [UsersController::class, 'show']);
    Route::patch('users/{id}/password', [UsersController::class, 'changePassword']);
    Route::patch('users/{id}/avatar', [UsersController::class, 'uploadAvatar']);
    Route::patch('users/{id}', [UsersController::class, 'update']);
    Route::delete('users/{id}', [UsersController::class, 'destroy'])->middleware('permission:manage_users');

    // ── Manage projects (admin) ──
    Route::prefix('manage/projects')->group(function () {
        Route::get('/', [ManageProjectController::class, 'index']);
        Route::post('/', [ManageProjectController::class, 'store'])->middleware('permission:create_project');
        Route::get('{id}/members', [ManageProjectController::class, 'members']);
        Route::post('{id}/members', [ManageProjectController::class, 'addMember'])->middleware('permission:edit_project');
        Route::delete('{id}/members/{userId}', [ManageProjectController::class, 'removeMember'])->middleware('permission:edit_project');
        Route::patch('{id}/archive', [ManageProjectController::class, 'archive'])->middleware('permission:edit_project');
        Route::patch('{id}/unarchive', [ManageProjectController::class, 'unarchive'])->middleware('permission:edit_project');
        Route::patch('{id}/restore', [ManageProjectController::class, 'restore'])->middleware('permission:edit_project');
        Route::patch('{id}/transfer-owner', [ManageProjectController::class, 'transferOwner'])->middleware('permission:delete_project');
        Route::patch('{id}', [ManageProjectController::class, 'update'])->middleware('permission:edit_project');
        Route::delete('{id}', [ManageProjectController::class, 'destroy'])->middleware('permission:delete_project');
    });

    // ── Projects ──
    Route::get('projects', [ProjectController::class, 'index']);
    Route::post('projects', [ProjectController::class, 'store'])->middleware('permission:create_project');
    Route::get('projects/{id}', [ProjectController::class, 'show']);

    // ── Per-project: members, columns, tasks ──
    Route::prefix('projects/{projectId}')->group(function () {
        Route::prefix('reports')->middleware('permission:view_reports')->group(function () {
            Route::get('summary', [ReportController::class, 'summary']);
            Route::get('developer-report', [ReportController::class, 'developer']);
            Route::get('weekly', [ReportController::class, 'weekly']);
            Route::get('monthly-kpi', [ReportController::class, 'monthly']);
            Route::get('productivity', [ReportController::class, 'productivity']);
            Route::get('completion-rate', [ReportController::class, 'completionRate']);
            Route::get('working-hours', [ReportController::class, 'workingHours']);
        });
        // ── Queued exports (Excel tasks / monthly PDF) ──
        Route::middleware('permission:view_reports')->group(function () {
            Route::post('export/tasks/excel', [ExportController::class, 'tasksExcel']);
            Route::post('export/reports/monthly/pdf', [ExportController::class, 'monthlyReportPdf']);
            Route::get('export/files/{fileName}', [ExportController::class, 'download'])->where('fileName', '.*');
        });

        Route::get('activity/export', [ActivityController::class, 'export'])->middleware('permission:view_reports');
        Route::get('activity', [ActivityController::class, 'index']);
        Route::get('members', [MemberController::class, 'index']);
        Route::post('members', [MemberController::class, 'store']);
        Route::patch('members/{userId}', [MemberController::class, 'updateRole']);
        Route::delete('members/{userId}', [MemberController::class, 'destroy']);

        Route::get('columns', [ColumnController::class, 'index']);
        Route::post('columns', [ColumnController::class, 'store']);
        Route::patch('columns/reorder', [ColumnController::class, 'reorder']);
        Route::patch('columns/{id}', [ColumnController::class, 'update']);
        Route::delete('columns/{id}', [ColumnController::class, 'destroy']);

        Route::get('tasks', [TaskController::class, 'index']);
        Route::post('tasks', [TaskController::class, 'store']);
        Route::get('tasks/{id}', [TaskController::class, 'show']);
        Route::patch('tasks/{id}/move', [TaskController::class, 'move']);
        Route::patch('tasks/{id}/archive', [TaskController::class, 'archive']);
        Route::patch('tasks/{id}/unarchive', [TaskController::class, 'unarchive']);
        Route::patch('tasks/{id}/restore', [TaskController::class, 'restore']);
        Route::post('tasks/{id}/log-time', [TaskController::class, 'logTime']);
        Route::get('archived', [ArchivedController::class, 'index']);
        Route::patch('tasks/{id}', [TaskController::class, 'update']);
        Route::delete('tasks/{id}', [TaskController::class, 'destroy']);

        // ── Sprints (UI dropped; kept so Board filter + Reports don't 404) ──
        Route::get('sprints', [SprintController::class, 'index']);
        Route::post('sprints', [SprintController::class, 'store']);
        Route::patch('sprints/{id}/start', [SprintController::class, 'start']);
        Route::patch('sprints/{id}/complete', [SprintController::class, 'complete']);
        Route::patch('sprints/{id}', [SprintController::class, 'update']);

        // ── Labels ──
        Route::get('labels', [LabelController::class, 'index']);
        Route::post('labels', [LabelController::class, 'store']);
        Route::patch('labels/{id}', [LabelController::class, 'update']);
        Route::delete('labels/{id}', [LabelController::class, 'destroy']);

        // ── Project-wide attachments ──
        Route::get('attachments', [AttachmentController::class, 'listForProject']);
        Route::get('attachments/file/{filename}', [AttachmentController::class, 'rawByName'])->where('filename', '.*');

        // ── Comments ──
        Route::get('tasks/{taskId}/comments', [CommentController::class, 'index']);
        Route::post('tasks/{taskId}/comments', [CommentController::class, 'store']);
        Route::patch('tasks/{taskId}/comments/{id}', [CommentController::class, 'update']);
        Route::delete('tasks/{taskId}/comments/{id}', [CommentController::class, 'destroy']);

        // ── Task attachments ──
        Route::get('tasks/{taskId}/attachments', [AttachmentController::class, 'index']);
        Route::post('tasks/{taskId}/attachments', [AttachmentController::class, 'store']);
        Route::get('tasks/{taskId}/attachments/{id}/download', [AttachmentController::class, 'download']);
        Route::delete('tasks/{taskId}/attachments/{id}', [AttachmentController::class, 'destroy']);

        // ── Task links ──
        Route::get('tasks/{taskId}/links', [TaskLinkController::class, 'index']);
        Route::post('tasks/{taskId}/links', [TaskLinkController::class, 'store']);
        Route::delete('tasks/{taskId}/links/{linkId}', [TaskLinkController::class, 'destroy']);
    });
});
