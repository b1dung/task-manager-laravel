<?php

namespace App\Http\Controllers;

use App\Events\ProjectEvent;
use App\Http\Resources\TaskUserResource;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WatcherController extends Controller
{
    /** Watchers ordered by when they started watching (Jira-style). */
    private function watchers(Task $task)
    {
        return $task->watchers()->orderBy('task_watchers.created_at')->get();
    }

    public function index(string $projectId, string $taskId): JsonResponse
    {
        $task = Task::where('project_id', $projectId)->findOrFail($taskId);

        return response()->ok(TaskUserResource::collection($this->watchers($task)));
    }

    public function store(Request $request, string $projectId, string $taskId): JsonResponse
    {
        $task = Task::where('project_id', $projectId)->findOrFail($taskId);
        $data = $request->validate(['userId' => ['nullable', 'uuid']]);
        $userId = $data['userId'] ?? $request->user()->id;

        $task->watchers()->syncWithoutDetaching([$userId]);
        ProjectEvent::dispatch($projectId, 'watcher:changed', ['taskId' => $task->id]);

        return response()->ok(TaskUserResource::collection($this->watchers($task)));
    }

    public function destroy(string $projectId, string $taskId, string $userId): JsonResponse
    {
        $task = Task::where('project_id', $projectId)->findOrFail($taskId);

        $task->watchers()->detach($userId);
        ProjectEvent::dispatch($projectId, 'watcher:changed', ['taskId' => $task->id]);

        return response()->ok(TaskUserResource::collection($this->watchers($task)));
    }
}
