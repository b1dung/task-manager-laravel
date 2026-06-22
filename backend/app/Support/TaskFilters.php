<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;

/**
 * Shared task list filtering, used by both the board listing (TaskController)
 * and the queued Excel export so the two stay in lock-step.
 * `$p` is the request query array (e.g. $request->query()).
 */
class TaskFilters
{
    public static function apply(Builder $query, array $p): void
    {
        $columnFilters = [
            'status' => 'status',
            'priority' => 'priority',
            'type' => 'type',
            'assigneeId' => 'assignee_id',
            'sprintId' => 'sprint_id',
        ];
        foreach ($columnFilters as $param => $column) {
            $values = self::toArray($p[$param] ?? null);
            if ($values) {
                $query->whereIn($column, $values);
            }
        }

        $labelIds = self::toArray($p['labelId'] ?? null);
        if ($labelIds) {
            $query->whereHas('labels', fn ($q) => $q->whereIn('labels.id', $labelIds));
        }

        if ($q = trim((string) ($p['q'] ?? $p['search'] ?? ''))) {
            $query->where(fn ($sub) => $sub->where('title', 'like', "%{$q}%")->orWhere('description', 'like', "%{$q}%"));
        }
        if ($from = ($p['createdFrom'] ?? null)) {
            $query->whereDate('created_at', '>=', $from);
        }
        if ($to = ($p['createdTo'] ?? null)) {
            $query->whereDate('created_at', '<=', $to);
        }

        $due = $p['due'] ?? null;
        $today = Carbon::now()->toDateString();
        match ($due) {
            'overdue' => $query->whereNotNull('due_date')->whereDate('due_date', '<', $today)->where('status', '!=', 'done'),
            'today' => $query->whereDate('due_date', $today),
            'this_week' => $query->whereBetween('due_date', [$today, Carbon::now()->addDays(7)->toDateString()]),
            'no_due_date' => $query->whereNull('due_date'),
            default => null,
        };
    }

    public static function toArray(mixed $value): array
    {
        if ($value === null || $value === '') {
            return [];
        }

        return is_array($value) ? $value : array_filter(explode(',', (string) $value));
    }
}
