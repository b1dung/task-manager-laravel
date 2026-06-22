<?php

namespace App\Http\Controllers;

use App\Http\Resources\TaskResource;
use App\Models\Task;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MyTasksController extends Controller
{
    /** GET /me/tasks — tasks related to the current user across all projects. */
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $scope = $request->query('scope', 'assigned');

        $base = fn (): Builder => Task::query()
            ->when($scope === 'reported',
                fn ($q) => $q->where('reporter_id', $userId),
                fn ($q) => $q->where('assignee_id', $userId),
            );

        $query = $base()->with(['assignee', 'reporter', 'labels', 'project']);
        if ($q = trim((string) $request->query('q', ''))) {
            $query->where('title', 'like', "%{$q}%");
        }
        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }
        if ($priority = $request->query('priority')) {
            $query->where('priority', $priority);
        }
        if ($projectId = $request->query('projectId')) {
            $query->where('project_id', $projectId);
        }

        $items = $query->orderBy('due_date')->get();
        $today = now()->toDateString();

        $stats = [
            'total' => $base()->count(),
            'dueToday' => $base()->whereDate('due_date', $today)->count(),
            'overdue' => $base()->whereDate('due_date', '<', $today)->where('status', '!=', 'done')->count(),
            'completed' => $base()->where('status', 'done')->count(),
            'inProgress' => $base()->where('status', 'in_progress')->count(),
        ];

        return response()->ok([
            'items' => TaskResource::collection($items),
            'stats' => $stats,
        ]);
    }
}
