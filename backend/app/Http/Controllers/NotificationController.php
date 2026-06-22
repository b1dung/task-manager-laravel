<?php

namespace App\Http\Controllers;

use App\Http\Resources\NotificationResource;
use App\Models\Comment;
use App\Models\Notification;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $page = max(1, (int) $request->query('page', 1));
        $limit = 30;

        $query = Notification::with('actor')->where('recipient_id', $userId)->orderBy('created_at', 'desc');
        if (filter_var($request->query('unread'), FILTER_VALIDATE_BOOL)) {
            $query->whereNull('read_at');
        }

        $total = (clone $query)->count();
        $items = $query->forPage($page, $limit)->get();

        // Resolve deep-link context for task notifications (batched).
        $commentIds = $items->where('entity_type', 'comment')->pluck('entity_id')->unique()->all();
        $commentTasks = Comment::whereIn('id', $commentIds)->pluck('task_id', 'id');
        $taskIds = $items->where('entity_type', 'task')->pluck('entity_id')->merge($commentTasks->values())->unique()->all();
        $tasks = Task::with('project')->whereIn('id', $taskIds)->get()->keyBy('id');
        $items->each(function ($n) use ($tasks, $commentTasks) {
            $taskId = $n->entity_type === 'task' ? $n->entity_id : ($n->entity_type === 'comment' ? $commentTasks->get($n->entity_id) : null);
            $task = $taskId ? $tasks->get($taskId) : null;
            $n->context_data = $task ? [
                'projectId' => $task->project_id,
                'projectName' => $task->project?->name,
                'taskId' => $task->id,
                'taskNumber' => $task->task_number,
                'taskTitle' => $task->title,
            ] : null;
        });

        return response()->paginated(NotificationResource::collection($items), $page, $limit, $total);
    }

    public function markRead(Request $request, string $id): JsonResponse
    {
        Notification::where('recipient_id', $request->user()->id)->where('id', $id)
            ->update(['read_at' => now()]);

        return response()->ok(null);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        Notification::where('recipient_id', $request->user()->id)->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->ok(null);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $count = Notification::where('recipient_id', $request->user()->id)->whereNull('read_at')->count();

        return response()->ok(['count' => $count]);
    }
}
