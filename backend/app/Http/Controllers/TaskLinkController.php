<?php

namespace App\Http\Controllers;

use App\Events\ProjectEvent;
use App\Http\Resources\TaskLinkResource;
use App\Models\Task;
use App\Models\TaskLink;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class TaskLinkController extends Controller
{
    public function index(string $projectId, string $taskId): JsonResponse
    {
        $links = TaskLink::with(['source.assignee', 'target.assignee'])
            ->where(fn ($q) => $q->where('source_task_id', $taskId)->orWhere('target_task_id', $taskId))
            ->get();

        return response()->ok(TaskLinkResource::collection($links));
    }

    public function store(Request $request, string $projectId, string $taskId): JsonResponse
    {
        $data = $request->validate([
            'targetTaskId' => ['required', 'uuid'],
            'linkType' => ['required', 'in:blocks,blocked_by,relates_to'],
        ]);

        if ($data['targetTaskId'] === $taskId) {
            throw ValidationException::withMessages(['targetTaskId' => 'A task cannot link to itself']);
        }

        // Target must belong to the same project.
        Task::where('project_id', $projectId)->findOrFail($data['targetTaskId']);

        $exists = TaskLink::where('source_task_id', $taskId)
            ->where('target_task_id', $data['targetTaskId'])
            ->where('link_type', $data['linkType'])
            ->exists();
        if ($exists) {
            throw ValidationException::withMessages(['linkType' => 'This link already exists']);
        }

        $link = TaskLink::create([
            'source_task_id' => $taskId,
            'target_task_id' => $data['targetTaskId'],
            'link_type' => $data['linkType'],
        ]);

        ProjectEvent::dispatch($projectId, 'tasklink:changed', ['taskId' => $taskId]);

        return response()->ok(new TaskLinkResource($link->load(['source', 'target'])), 201);
    }

    public function destroy(string $projectId, string $taskId, string $linkId): JsonResponse
    {
        TaskLink::where('id', $linkId)
            ->where(fn ($q) => $q->where('source_task_id', $taskId)->orWhere('target_task_id', $taskId))
            ->firstOrFail()
            ->delete();

        ProjectEvent::dispatch($projectId, 'tasklink:changed', ['taskId' => $taskId]);

        return response()->ok(null);
    }
}
