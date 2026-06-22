<?php

namespace App\Http\Controllers;

use App\Http\Resources\ColumnResource;
use App\Models\Column;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ColumnController extends Controller
{
    public function index(string $projectId): JsonResponse
    {
        $columns = Column::where('project_id', $projectId)->orderBy('position')->get();

        return response()->ok(ColumnResource::collection($columns));
    }

    public function store(Request $request, string $projectId): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string'],
            'color' => ['nullable', 'string'],
        ]);

        $position = (int) Column::where('project_id', $projectId)->max('position');
        $column = Column::create([
            'project_id' => $projectId,
            'name' => $data['name'],
            'color' => $data['color'] ?? null,
            'position' => Column::where('project_id', $projectId)->exists() ? $position + 1 : 0,
        ]);

        return response()->ok(new ColumnResource($column), 201);
    }

    public function update(Request $request, string $projectId, string $id): JsonResponse
    {
        $data = $request->validate([
            'name' => ['nullable', 'string'],
            'color' => ['nullable', 'string'],
            'wipLimit' => ['nullable', 'integer', 'min:0'],
        ]);

        $column = Column::where('project_id', $projectId)->findOrFail($id);
        if (! empty($data['name'])) {
            $column->name = $data['name'];
        }
        if ($request->has('color')) {
            $column->color = $data['color'] ?: null; // '' clears the color
        }
        if ($request->has('wipLimit')) {
            $column->wip_limit = $data['wipLimit'];
        }
        $column->save();

        return response()->ok(new ColumnResource($column));
    }

    public function destroy(string $projectId, string $id): JsonResponse
    {
        $column = Column::where('project_id', $projectId)->findOrFail($id);
        if (Task::where('column_id', $column->id)->exists()) {
            abort(400, 'Cannot delete a column with tasks');
        }
        $column->delete();

        return response()->ok(null);
    }

    public function reorder(Request $request, string $projectId): JsonResponse
    {
        $data = $request->validate([
            'columnIds' => ['required', 'array'],
            'columnIds.*' => ['uuid'],
        ]);

        foreach ($data['columnIds'] as $i => $columnId) {
            Column::where('project_id', $projectId)->where('id', $columnId)->update(['position' => $i]);
        }

        return response()->ok(null);
    }
}
