<?php

namespace App\Http\Controllers;

use App\Http\Resources\ActivityResource;
use App\Models\ActivityLog;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ActivityController extends Controller
{
    public function index(Request $request, string $projectId): JsonResponse
    {
        $page = max(1, (int) $request->query('page', 1));
        $limit = min(200, max(1, (int) $request->query('limit', 50)));
        $query = $this->query($request, $projectId);
        $total = (clone $query)->count();
        $items = $query->with('user')->orderByDesc('created_at')->forPage($page, $limit)->get();

        return response()->paginated(ActivityResource::collection($items), $page, $limit, $total);
    }

    public function export(Request $request, string $projectId): StreamedResponse
    {
        $file = 'activity-'.$projectId.'-'.now()->format('Ymd-His').'.csv';

        return response()->streamDownload(function () use ($request, $projectId) {
            $out = fopen('php://output', 'w');
            fwrite($out, "\xEF\xBB\xBF");
            fputcsv($out, ['id', 'projectId', 'userId', 'action', 'entityType', 'entityId', 'oldValues', 'newValues', 'createdAt']);
            $this->query($request, $projectId)->orderByDesc('created_at')->chunk(500, function ($rows) use ($out) {
                foreach ($rows as $row) {
                    fputcsv($out, [$row->id, $row->project_id, $row->user_id, $row->action, $row->entity_type, $row->entity_id, json_encode($row->old_values_json), json_encode($row->new_values_json), $row->created_at?->toIso8601String()]);
                }
            });
            fclose($out);
        }, $file, ['Content-Type' => 'text/csv; charset=UTF-8']);
    }

    private function query(Request $request, string $projectId): Builder
    {
        $query = ActivityLog::where('project_id', $projectId);
        if ($request->filled('userId')) {
            $query->where('user_id', $request->query('userId'));
        }
        // History tab passes entityId to scope to a single task — without this the
        // query returned every task's activity for the whole project.
        if ($request->filled('entityId')) {
            $query->where('entity_id', $request->query('entityId'));
        }
        foreach (['action' => 'action', 'entityType' => 'entity_type'] as $param => $column) {
            $values = $this->toArray($request->query($param));
            if ($values) {
                $query->whereIn($column, $values);
            }
        }
        if ($request->filled('from')) {
            $query->where('created_at', '>=', $request->query('from'));
        }
        if ($request->filled('to')) {
            $query->where('created_at', '<=', $request->query('to').' 23:59:59');
        }

        return $query;
    }

    private function toArray(mixed $value): array
    {
        if ($value === null || $value === '') {
            return [];
        }

        return array_values(array_filter(is_array($value) ? $value : explode(',', (string) $value)));
    }
}
