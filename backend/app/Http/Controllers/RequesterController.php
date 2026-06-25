<?php

namespace App\Http\Controllers;

use App\Http\Resources\RequesterResource;
use App\Models\Requester;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RequesterController extends Controller
{
    public function index(string $projectId): JsonResponse
    {
        $requesters = Requester::where('project_id', $projectId)->orderBy('name')->get();

        return response()->ok(RequesterResource::collection($requesters));
    }

    public function store(Request $request, string $projectId): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string'],
            'color' => ['required', 'string'],
        ]);

        $requester = Requester::create([
            'project_id' => $projectId,
            'name' => $data['name'],
            'color' => $data['color'],
        ]);

        return response()->ok(new RequesterResource($requester), 201);
    }

    public function update(Request $request, string $projectId, string $id): JsonResponse
    {
        $data = $request->validate([
            'name' => ['nullable', 'string'],
            'color' => ['nullable', 'string'],
        ]);

        $requester = Requester::where('project_id', $projectId)->findOrFail($id);
        $requester->fill(array_filter([
            'name' => $data['name'] ?? null,
            'color' => $data['color'] ?? null,
        ]))->save();

        return response()->ok(new RequesterResource($requester));
    }

    public function destroy(string $projectId, string $id): JsonResponse
    {
        Requester::where('project_id', $projectId)->findOrFail($id)->delete();

        return response()->ok(null);
    }
}
