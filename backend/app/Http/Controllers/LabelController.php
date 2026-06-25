<?php

namespace App\Http\Controllers;

use App\Events\ProjectEvent;
use App\Http\Resources\LabelResource;
use App\Models\Label;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LabelController extends Controller
{
    public function index(string $projectId): JsonResponse
    {
        $labels = Label::where('project_id', $projectId)->orderBy('name')->get();

        return response()->ok(LabelResource::collection($labels));
    }

    public function store(Request $request, string $projectId): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string'],
            'color' => ['required', 'string'],
        ]);

        $label = Label::create([
            'project_id' => $projectId,
            'name' => $data['name'],
            'color' => $data['color'],
        ]);

        ProjectEvent::dispatch($projectId, 'label:changed', ['labelId' => $label->id]);

        return response()->ok(new LabelResource($label), 201);
    }

    public function update(Request $request, string $projectId, string $id): JsonResponse
    {
        $data = $request->validate([
            'name' => ['nullable', 'string'],
            'color' => ['nullable', 'string'],
        ]);

        $label = Label::where('project_id', $projectId)->findOrFail($id);
        $label->fill(array_filter([
            'name' => $data['name'] ?? null,
            'color' => $data['color'] ?? null,
        ]))->save();

        ProjectEvent::dispatch($projectId, 'label:changed', ['labelId' => $label->id]);

        return response()->ok(new LabelResource($label));
    }

    public function destroy(string $projectId, string $id): JsonResponse
    {
        Label::where('project_id', $projectId)->findOrFail($id)->delete();

        ProjectEvent::dispatch($projectId, 'label:changed', ['labelId' => $id]);

        return response()->ok(null);
    }
}
