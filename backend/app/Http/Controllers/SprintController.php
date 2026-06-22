<?php

namespace App\Http\Controllers;

use App\Http\Resources\SprintResource;
use App\Models\Sprint;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Sprints were dropped from the UI but the Board filter and Reports page still
 * fetch the list, so this keeps the contract alive (the table/model exist).
 */
class SprintController extends Controller
{
    public function index(string $projectId): JsonResponse
    {
        $sprints = Sprint::where('project_id', $projectId)->orderBy('start_date')->get();

        return response()->ok(SprintResource::collection($sprints));
    }

    public function store(Request $request, string $projectId): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string'],
            'goal' => ['nullable', 'string'],
            'startDate' => ['nullable', 'date'],
            'endDate' => ['nullable', 'date'],
        ]);

        $sprint = Sprint::create([
            'project_id' => $projectId,
            'name' => $data['name'],
            'goal' => $data['goal'] ?? null,
            'start_date' => $data['startDate'] ?? null,
            'end_date' => $data['endDate'] ?? null,
            'status' => 'planned',
        ]);

        return response()->ok(new SprintResource($sprint), 201);
    }

    public function update(Request $request, string $projectId, string $id): JsonResponse
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string'],
            'goal' => ['sometimes', 'nullable', 'string'],
            'startDate' => ['sometimes', 'nullable', 'date'],
            'endDate' => ['sometimes', 'nullable', 'date'],
            'status' => ['sometimes', 'in:planned,active,completed'],
        ]);

        $sprint = Sprint::where('project_id', $projectId)->findOrFail($id);
        $sprint->fill(array_filter([
            'name' => $data['name'] ?? null,
            'goal' => $data['goal'] ?? null,
            'start_date' => $data['startDate'] ?? null,
            'end_date' => $data['endDate'] ?? null,
            'status' => $data['status'] ?? null,
        ], fn ($v) => $v !== null))->save();

        return response()->ok(new SprintResource($sprint));
    }

    public function start(string $projectId, string $id): JsonResponse
    {
        return $this->setStatus($projectId, $id, 'active');
    }

    public function complete(string $projectId, string $id): JsonResponse
    {
        return $this->setStatus($projectId, $id, 'completed');
    }

    private function setStatus(string $projectId, string $id, string $status): JsonResponse
    {
        $sprint = Sprint::where('project_id', $projectId)->findOrFail($id);
        $sprint->status = $status;
        $sprint->save();

        return response()->ok(new SprintResource($sprint));
    }
}
