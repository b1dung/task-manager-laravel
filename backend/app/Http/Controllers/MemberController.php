<?php

namespace App\Http\Controllers;

use App\Http\Resources\MemberResource;
use App\Models\ProjectMember;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MemberController extends Controller
{
    public function index(Request $request, string $projectId): JsonResponse
    {
        $members = ProjectMember::with('user')->where('project_id', $projectId)->get();

        // Attach each member's assigned-task count in this project.
        $counts = Task::where('project_id', $projectId)
            ->whereNotNull('assignee_id')
            ->selectRaw('assignee_id, count(*) as c')
            ->groupBy('assignee_id')
            ->pluck('c', 'assignee_id');

        $members->each(fn ($m) => $m->task_count = (int) ($counts[$m->user_id] ?? 0));

        return response()->ok(MemberResource::collection($members));
    }

    public function store(Request $request, string $projectId): JsonResponse
    {
        $data = $request->validate([
            'userId' => ['required', 'uuid'],
            'role' => ['nullable', 'in:admin,manager,member,viewer'],
        ]);

        $member = ProjectMember::firstOrCreate(
            ['project_id' => $projectId, 'user_id' => $data['userId']],
            ['role' => $data['role'] ?? 'member'],
        );
        $member->load('user');

        return response()->ok(new MemberResource($member), 201);
    }

    public function updateRole(Request $request, string $projectId, string $userId): JsonResponse
    {
        $data = $request->validate(['role' => ['required', 'in:admin,manager,member,viewer']]);

        $member = ProjectMember::where('project_id', $projectId)->where('user_id', $userId)->firstOrFail();
        $member->update(['role' => $data['role']]);
        $member->load('user');

        return response()->ok(new MemberResource($member));
    }

    public function destroy(string $projectId, string $userId): JsonResponse
    {
        ProjectMember::where('project_id', $projectId)->where('user_id', $userId)->delete();

        return response()->ok(null);
    }
}
