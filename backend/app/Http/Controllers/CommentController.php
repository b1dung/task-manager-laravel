<?php

namespace App\Http\Controllers;

use App\Events\ProjectEvent;
use App\Http\Resources\CommentResource;
use App\Models\Comment;
use App\Models\CommentMention;
use App\Models\ProjectMember;
use App\Models\Task;
use App\Services\ActivityService;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    public function __construct(private readonly ActivityService $activity, private readonly NotificationService $notifications) {}

    public function index(string $projectId, string $taskId): JsonResponse
    {
        $comments = Comment::with(['author', 'replies' => fn ($q) => $q->with('author')->orderBy('created_at')])
            ->where('task_id', $taskId)
            ->whereNull('parent_id')
            ->orderBy('created_at')
            ->get();

        return response()->ok(CommentResource::collection($comments));
    }

    public function store(Request $request, string $projectId, string $taskId): JsonResponse
    {
        $data = $request->validate([
            'content' => ['required', 'string'],
            'parentId' => ['nullable', 'uuid'],
            'mentionedUserIds' => ['nullable', 'array'],
            'mentionedUserIds.*' => ['uuid'],
        ]);

        $mentioned = array_values(array_unique($data['mentionedUserIds'] ?? []));
        if ($mentioned && ProjectMember::where('project_id', $projectId)->whereIn('user_id', $mentioned)->count() !== count($mentioned)) {
            abort(422, 'One or more mentioned users are not members of this project');
        }
        $task = Task::where('project_id', $projectId)->findOrFail($taskId);

        $comment = Comment::create([
            'task_id' => $taskId,
            'author_id' => $request->user()->id,
            'content' => $data['content'],
            'parent_id' => $data['parentId'] ?? null,
        ]);

        foreach ($mentioned as $userId) {
            CommentMention::create(['comment_id' => $comment->id, 'user_id' => $userId]);
        }
        $this->activity->record($request, $projectId, 'commented', 'comment', $comment->id, null, ['taskId' => $taskId, 'content' => $comment->content]);
        $personal = array_values(array_filter($mentioned, fn ($id) => $id !== $request->user()->id));
        if ($personal) {
            $this->notifications->taskEvent($projectId, $request->user()->id, 'mention', 'comment', $comment->id, 'mentioned you in a comment on "'.$task->title.'"', $personal, [], false);
        }
        $this->notifications->taskEvent($projectId, $request->user()->id, 'comment_added', 'comment', $comment->id, 'commented on "'.$task->title.'"', [$task->assignee_id, $task->reporter_id], $personal);
        ProjectEvent::dispatch($projectId, 'comment:added', ['taskId' => $taskId, 'comment' => (new CommentResource($comment->load('author')))->resolve()]);

        return response()->ok(new CommentResource($comment->load('author')), 201);
    }

    public function update(Request $request, string $projectId, string $taskId, string $id): JsonResponse
    {
        $data = $request->validate(['content' => ['required', 'string']]);

        $comment = Comment::where('task_id', $taskId)->findOrFail($id);
        abort_unless($comment->author_id === $request->user()->id, 403, 'You can only edit your own comment');

        $comment->update(['content' => $data['content'], 'edited_at' => now()]);

        return response()->ok(new CommentResource($comment->load('author')));
    }

    public function destroy(Request $request, string $projectId, string $taskId, string $id): JsonResponse
    {
        $comment = Comment::where('task_id', $taskId)->findOrFail($id);
        abort_unless(
            $comment->author_id === $request->user()->id || $request->user()->hasPermission('approve_task'),
            403,
            'Not allowed',
        );
        $comment->delete();

        return response()->ok(null);
    }
}
