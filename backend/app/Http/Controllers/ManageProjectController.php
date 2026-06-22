<?php

namespace App\Http\Controllers;

use App\Http\Resources\ManagedMemberResource;
use App\Http\Resources\ManagedProjectResource;
use App\Models\Column;
use App\Models\Project;
use App\Models\ProjectMember;
use App\Models\ProjectTaskCounter;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ManageProjectController extends Controller
{
    public function index(): JsonResponse
    {
        $projects = Project::with('owner')->withCount(['tasks', 'members'])
            ->orderBy('created_at', 'desc')->get();

        return response()->ok(ManagedProjectResource::collection($projects));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'min:2'],
            'slug' => ['nullable', 'string'],
            'description' => ['nullable', 'string'],
        ]);
        $user = $request->user();

        $project = DB::transaction(function () use ($data, $user) {
            $project = Project::create([
                'name' => $data['name'],
                'slug' => $this->uniqueSlug($data['slug'] ?? $data['name']),
                'description' => $data['description'] ?? null,
                'owner_id' => $user->id,
            ]);
            foreach (['To Do', 'In Progress', 'In Review', 'Done'] as $i => $name) {
                Column::create(['project_id' => $project->id, 'name' => $name, 'position' => $i]);
            }
            ProjectMember::create(['project_id' => $project->id, 'user_id' => $user->id, 'role' => 'admin']);
            ProjectTaskCounter::create(['project_id' => $project->id, 'last_number' => 0]);

            return $project;
        });

        return response()->ok(new ManagedProjectResource($project->fresh()), 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'name' => ['nullable', 'string', 'min:2'],
            'description' => ['nullable', 'string'],
            'deadline' => ['nullable', 'date'],
        ]);
        $project = Project::findOrFail($id);
        if ($request->has('name')) {
            $project->name = $data['name'];
        }
        if ($request->has('description')) {
            $project->description = $data['description'];
        }
        if ($request->has('deadline')) {
            $project->deadline = $data['deadline'];
        }
        $project->save();

        return response()->ok(new ManagedProjectResource($project));
    }

    public function archive(string $id): JsonResponse
    {
        $project = Project::findOrFail($id);
        $project->update(['archived_at' => now()]);

        return response()->ok(new ManagedProjectResource($project));
    }

    public function unarchive(string $id): JsonResponse
    {
        $project = Project::findOrFail($id);
        $project->update(['archived_at' => null]);

        return response()->ok(new ManagedProjectResource($project));
    }

    public function destroy(string $id): JsonResponse
    {
        $project = Project::findOrFail($id);
        $taskCount = Task::where('project_id', $project->id)->count();
        $project->delete(); // soft delete

        return response()->ok(['taskCount' => $taskCount]);
    }

    public function restore(string $id): JsonResponse
    {
        $project = Project::withTrashed()->findOrFail($id);
        $project->restore();

        return response()->ok(new ManagedProjectResource($project));
    }

    public function transferOwner(Request $request, string $id): JsonResponse
    {
        $data = $request->validate(['ownerId' => ['required', 'uuid']]);
        $project = Project::findOrFail($id);

        // Ensure the new owner is a member.
        ProjectMember::firstOrCreate(
            ['project_id' => $project->id, 'user_id' => $data['ownerId']],
            ['role' => 'admin'],
        );
        $project->update(['owner_id' => $data['ownerId']]);

        return response()->ok(new ManagedProjectResource($project->load('owner')));
    }

    public function members(string $id): JsonResponse
    {
        $members = ProjectMember::with('user')->where('project_id', $id)->get();

        return response()->ok(ManagedMemberResource::collection($members));
    }

    public function addMember(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'userId' => ['required', 'uuid'],
            'role' => ['nullable', 'in:admin,manager,member,viewer'],
        ]);
        $member = ProjectMember::firstOrCreate(
            ['project_id' => $id, 'user_id' => $data['userId']],
            ['role' => $data['role'] ?? 'member'],
        );

        return response()->ok(new ManagedMemberResource($member->load('user')), 201);
    }

    public function removeMember(string $id, string $userId): JsonResponse
    {
        ProjectMember::where('project_id', $id)->where('user_id', $userId)->delete();

        return response()->ok(null);
    }

    private function uniqueSlug(string $base): string
    {
        $slug = Str::slug($base) ?: 'project';
        $candidate = $slug;
        $n = 1;
        while (Project::withTrashed()->where('slug', $candidate)->exists()) {
            $candidate = $slug.'-'.(++$n);
        }

        return $candidate;
    }
}
