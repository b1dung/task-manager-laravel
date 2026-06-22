<?php

namespace App\Http\Controllers;

use App\Models\Project;
use App\Models\Task;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class ArchivedController extends Controller
{
    /** GET /projects/{projectId}/archived — archived tasks (this project) + archived projects. */
    public function index(string $projectId): JsonResponse
    {
        $tasks = Task::whereNotNull('archived_at')->where('project_id', $projectId)
            ->with(['assignee', 'column', 'sprint'])->orderBy('archived_at', 'desc')->get();

        $projects = Project::whereNotNull('archived_at')->with('owner')
            ->withCount(['tasks', 'members'])->orderBy('archived_at', 'desc')->get();

        // Resolve archived_by users (batched).
        $byIds = $tasks->pluck('archived_by')->merge($projects->pluck('archived_by'))->filter()->unique()->all();
        $users = User::whereIn('id', $byIds)->get()->keyBy('id');
        $userMini = fn (?string $id) => ($id && $users->has($id)) ? [
            'id' => $users[$id]->id,
            'fullName' => $users[$id]->full_name,
            'avatarUrl' => $users[$id]->avatar_url,
        ] : null;

        return response()->ok([
            'tasks' => $tasks->map(fn ($t) => [
                'id' => $t->id,
                'taskNumber' => $t->task_number,
                'title' => $t->title,
                'type' => $t->type,
                'status' => $t->status,
                'assignee' => $t->assignee ? [
                    'id' => $t->assignee->id,
                    'fullName' => $t->assignee->full_name,
                    'avatarUrl' => $t->assignee->avatar_url,
                ] : null,
                'columnId' => $t->column_id,
                'columnName' => $t->column?->name,
                'sprintId' => $t->sprint_id,
                'sprintName' => $t->sprint?->name,
                'archivedAt' => $t->archived_at?->toIso8601String(),
                'archivedBy' => $userMini($t->archived_by),
            ]),
            'projects' => $projects->map(fn ($p) => [
                'id' => $p->id,
                'name' => $p->name,
                'slug' => $p->slug,
                'taskCount' => (int) $p->tasks_count,
                'memberCount' => (int) $p->members_count,
                'owner' => $p->owner ? [
                    'id' => $p->owner->id,
                    'fullName' => $p->owner->full_name,
                    'avatarUrl' => $p->owner->avatar_url,
                ] : null,
                'archivedAt' => $p->archived_at?->toIso8601String(),
                'archivedBy' => $userMini($p->archived_by),
            ]),
        ]);
    }
}
