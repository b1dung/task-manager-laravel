<?php

namespace App\Http\Controllers;

use App\Http\Resources\ProjectResource;
use App\Models\Column;
use App\Models\Project;
use App\Models\ProjectMember;
use App\Models\ProjectTaskCounter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ProjectController extends Controller
{
    /** Projects the user belongs to (or all, with view_all_projects). */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Project::query()->orderBy('created_at', 'desc');
        if (! $user->hasPermission('view_all_projects')) {
            $memberIds = ProjectMember::where('user_id', $user->id)->pluck('project_id');
            $query->where(fn ($q) => $q->whereIn('id', $memberIds)->orWhere('owner_id', $user->id));
        }

        return response()->ok(ProjectResource::collection($query->get()));
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $project = Project::findOrFail($id);
        $this->assertMember($request, $project);

        return response()->ok(new ProjectResource($project));
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

            // Default board columns.
            foreach (['To Do', 'In Progress', 'In Review', 'Done'] as $i => $name) {
                Column::create(['project_id' => $project->id, 'name' => $name, 'position' => $i]);
            }

            ProjectMember::create([
                'project_id' => $project->id,
                'user_id' => $user->id,
                'role' => 'admin',
            ]);

            ProjectTaskCounter::create(['project_id' => $project->id, 'last_number' => 0]);

            return $project;
        });

        return response()->ok(new ProjectResource($project->fresh()), 201);
    }

    private function uniqueSlug(string $base): string
    {
        $slug = Str::slug($base) ?: 'project';
        $candidate = $slug;
        $n = 1;
        while (Project::where('slug', $candidate)->exists()) {
            $candidate = $slug.'-'.(++$n);
        }

        return $candidate;
    }

    private function assertMember(Request $request, Project $project): void
    {
        $user = $request->user();
        if ($user->hasPermission('view_all_projects') || $project->owner_id === $user->id) {
            return;
        }
        $isMember = ProjectMember::where('project_id', $project->id)->where('user_id', $user->id)->exists();
        abort_unless($isMember, 403, 'You are not a member of this project');
    }
}
