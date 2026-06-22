<?php

namespace App\Services;

use App\Models\ActivityLog;
use App\Models\Task;
use App\Models\WorkingHour;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportService
{
    public function summary(string $projectId): array
    {
        $base = fn () => Task::where('project_id', $projectId);
        $today = now()->toDateString();
        $weekAgo = now()->subDays(7);
        $status = $base()->select('status', DB::raw('COUNT(*) count'))->groupBy('status')->get();
        $priority = $base()->select('priority', DB::raw('COUNT(*) count'))->groupBy('priority')->get();
        $types = $base()->select('type', DB::raw('COUNT(*) count'))->groupBy('type')->get();
        $workload = $base()->join('users', 'users.id', '=', 'tasks.assignee_id')
            ->select('users.id as userId', 'users.full_name as fullName', 'users.avatar_url as avatarUrl', DB::raw('COUNT(*) assigned'), DB::raw("SUM(CASE WHEN tasks.status='done' THEN 1 ELSE 0 END) completed"))
            ->groupBy('users.id', 'users.full_name', 'users.avatar_url')->orderByDesc('assigned')->get();
        $recent = ActivityLog::where('activity_logs.project_id', $projectId)->leftJoin('users', 'users.id', '=', 'activity_logs.user_id')
            ->leftJoin('tasks', fn ($j) => $j->on('tasks.id', '=', 'activity_logs.entity_id')->where('activity_logs.entity_type', 'task'))
            ->select('activity_logs.*', 'users.full_name as userName', 'users.avatar_url as userAvatar', 'tasks.title as taskTitle', 'tasks.task_number as taskNumber')->latest('activity_logs.created_at')->limit(15)->get();
        $blocked = DB::table('tasks as t')->join('task_links as l', function ($j) {
            $j->on('l.source_task_id', '=', 't.id')->where('l.link_type', 'blocked_by')->orOn('l.target_task_id', '=', 't.id')->where('l.link_type', 'blocks');
        })->where('t.project_id', $projectId)->where('t.status', '!=', 'done')->whereNull('t.deleted_at')->distinct('t.id')->count('t.id');

        return [
            'kpis' => [
                'completed' => $base()->where('status', 'done')->where('updated_at', '>=', $weekAgo)->count(),
                'updated' => $base()->where('updated_at', '>=', $weekAgo)->count(),
                'created' => $base()->where('created_at', '>=', $weekAgo)->count(),
                'dueSoon' => $base()->where('status', '!=', 'done')->whereBetween('due_date', [$today, now()->addDays(7)->toDateString()])->count(),
                'overdue' => $base()->where('status', '!=', 'done')->whereDate('due_date', '<', $today)->count(),
                'blocked' => $blocked,
            ],
            'total' => $base()->count(),
            'statusOverview' => $status->map(fn ($r) => ['status' => $r->status, 'count' => (int) $r->count]),
            'priorityDistribution' => $priority->map(fn ($r) => ['priority' => $r->priority, 'count' => (int) $r->count]),
            'taskTypes' => $types->map(fn ($r) => ['type' => $r->type, 'count' => (int) $r->count]),
            'teamWorkload' => $workload->map(fn ($r) => ['userId' => $r->userId, 'fullName' => $r->fullName, 'avatarUrl' => $r->avatarUrl, 'assigned' => (int) $r->assigned, 'completed' => (int) $r->completed]),
            'recentActivities' => $recent->map(fn ($r) => ['id' => $r->id, 'action' => $r->action, 'entityType' => $r->entity_type, 'userId' => $r->user_id, 'userName' => $r->userName, 'userAvatar' => $r->userAvatar, 'taskTitle' => $r->taskTitle, 'taskNumber' => $r->taskNumber === null ? null : (int) $r->taskNumber, 'createdAt' => Carbon::parse($r->created_at)->toIso8601String()]),
        ];
    }

    public function developer(string $projectId, Request $request): array
    {
        [$from, $to] = $this->range($request, 30);
        $query = Task::with('assignee')->where('project_id', $projectId)->whereNotNull('assignee_id')->whereBetween('created_at', [$from, $to]);
        $this->filters($query, $request);
        $tasks = $query->get();
        $hours = WorkingHour::whereHas('task', fn ($q) => $q->where('project_id', $projectId))->whereBetween('logged_date', [$from->toDateString(), $to->toDateString()])->get();
        $hoursByUser = $hours->groupBy('user_id')->map(fn ($rows) => (float) $rows->sum('hours'));
        $today = now()->startOfDay();
        $details = [];
        $completion = [];
        $distribution = [];
        $late = ['On Time' => 0, 'Late < 3 days' => 0, 'Late 3-7 days' => 0, 'Late > 7 days' => 0];
        $developers = [];
        foreach ($tasks->groupBy('assignee_id') as $userId => $rows) {
            $completed = $rows->where('status', 'done');
            $overdue = $rows->filter(fn ($t) => $t->status !== 'done' && $t->due_date && $t->due_date->lt($today))->count();
            $avgDuration = $completed->count() ? $completed->avg(fn ($t) => $t->created_at->diffInSeconds($t->updated_at) / 86400) : 0;
            $rate = $rows->count() ? $completed->count() / $rows->count() : 0;
            $logged = (float) ($hoursByUser[$userId] ?? 0);
            $onTimeEligible = $completed->filter(fn ($t) => $t->due_date)->count();
            $onTime = $completed->filter(fn ($t) => $t->due_date && $t->updated_at->startOfDay()->lte($t->due_date))->count();
            $onTimeRate = $onTimeEligible ? $onTime / $onTimeEligible : $rate;
            $score = (int) round(($rate * .4 + min($logged / max($rows->count() * 8, 1), 1) * .25 + $onTimeRate * .2 + .5 * .15) * 100);
            $user = $rows->first()->assignee;
            $developers[] = ['userId' => $userId, 'fullName' => $user?->full_name ?? 'Unknown', 'avatarUrl' => $user?->avatar_url, 'assigned' => $rows->count(), 'completed' => $completed->count(), 'completionRate' => (int) round($rate * 100), 'loggedHours' => round($logged, 1), 'avgDuration' => round($avgDuration, 1), 'overdue' => $overdue, 'productivityScore' => $score, 'grade' => $score >= 85 ? 'excellent' : ($score >= 70 ? 'good' : ($score >= 50 ? 'average' : 'poor'))];
        }
        foreach ($tasks as $task) {
            $distribution[$task->status] = ($distribution[$task->status] ?? 0) + 1;
            $doneDate = $task->status === 'done' ? $task->updated_at->toDateString() : null;
            if ($doneDate) {
                $completion[$doneDate] = ($completion[$doneDate] ?? 0) + 1;
            }
            $lateDays = 0;
            $overdue = $task->status !== 'done' && $task->due_date && $task->due_date->lt($today);
            if ($task->due_date && $task->status === 'done') {
                $lateDays = max(0, $task->due_date->diffInDays($task->updated_at->startOfDay(), false));
                $bucket = $lateDays <= 0 ? 'On Time' : ($lateDays < 3 ? 'Late < 3 days' : ($lateDays <= 7 ? 'Late 3-7 days' : 'Late > 7 days'));
                $late[$bucket]++;
            } elseif ($overdue) {
                $lateDays = $task->due_date->diffInDays($today);
            }
            $details[] = ['id' => $task->id, 'taskNumber' => $task->task_number, 'title' => $task->title, 'priority' => $task->priority, 'status' => $task->status, 'estimatedHours' => $task->estimated_hours === null ? null : (float) $task->estimated_hours, 'loggedHours' => $task->logged_hours === null ? null : (float) $task->logged_hours, 'dueDate' => $task->due_date?->toDateString(), 'completedDate' => $doneDate, 'overdue' => (bool) $overdue, 'lateDays' => (int) $lateDays];
        }
        usort($developers, fn ($a, $b) => $b['productivityScore'] <=> $a['productivityScore']);
        $total = $tasks->count();
        $done = $tasks->where('status', 'done')->count();
        $logged = (float) $hours->sum('hours');
        $avgScore = count($developers) ? (int) round(array_sum(array_column($developers, 'productivityScore')) / count($developers)) : 0;
        $weeks = $hours->groupBy(fn ($h) => $h->logged_date->format('o-\WW'))->map(fn ($rows, $week) => ['week' => $week, 'hours' => round((float) $rows->sum('hours'), 1)])->sortKeys()->values();
        $labels = ['todo' => 'To Do', 'in_progress' => 'In Progress', 'in_review' => 'Review', 'done' => 'Delivered'];
        ksort($completion);

        return ['kpis' => ['totalTasks' => $total, 'completedTasks' => $done, 'completionRate' => $total ? (int) round($done / $total * 100) : 0, 'loggedHours' => round($logged, 1), 'overdueTasks' => array_sum(array_column($developers, 'overdue')), 'avgCompletionTime' => count($developers) ? round(array_sum(array_column($developers, 'avgDuration')) / count($developers), 1) : 0, 'productivityScore' => $avgScore], 'developers' => $developers, 'taskDistribution' => collect($distribution)->map(fn ($v, $k) => ['name' => $labels[$k] ?? $k, 'value' => $v])->values(), 'loggedHoursTrend' => $weeks, 'completionTrend' => collect($completion)->map(fn ($v, $k) => ['date' => $k, 'completed' => $v])->values(), 'overdueAnalysis' => collect($late)->map(fn ($v, $k) => ['name' => $k, 'value' => $v])->values(), 'taskDetails' => $details];
    }

    public function completions(string $projectId, Request $request, int $days): array
    {
        [$from, $to] = $this->range($request, $days);
        $q = Task::where('project_id', $projectId)->where('status', 'done')->whereBetween('updated_at', [$from, $to]);
        $this->filters($q, $request);

        return $q->selectRaw('DATE(updated_at) date, COUNT(*) completed')->groupByRaw('DATE(updated_at)')->orderBy('date')->get()->map(fn ($r) => ['date' => $r->date, 'completed' => (int) $r->completed])->all();
    }

    public function monthly(string $projectId, Request $request): array
    {
        [$from, $to] = $this->range($request, 30);
        $total = Task::where('project_id', $projectId)->whereBetween('created_at', [$from, $to]);
        $this->filters($total, $request);
        $target = $total->count();
        $done = Task::where('project_id', $projectId)->where('status', 'done')->whereBetween('updated_at', [$from, $to]);
        $this->filters($done, $request);
        $actual = $done->count();

        return ['from' => $from->toIso8601String(), 'to' => $to->toIso8601String(), 'target' => $target, 'actual' => $actual, 'completionRate' => $target ? round($actual / $target * 100, 1) : 0];
    }

    public function completionRate(string $projectId, Request $request): array
    {
        $q = Task::where('project_id', $projectId);
        $this->filters($q, $request);

        return $q->select('status', DB::raw('COUNT(*) count'))->groupBy('status')->get()->map(fn ($r) => ['status' => $r->status, 'count' => (int) $r->count])->all();
    }

    public function workingHours(string $projectId, Request $request): array
    {
        [$from, $to] = $this->range($request, 30);
        $estimated = Task::where('project_id', $projectId)->whereNotNull('assignee_id');
        $this->filters($estimated, $request);
        $estimated = $estimated->selectRaw('assignee_id userId, SUM(estimated_hours) estimatedHours')->groupBy('assignee_id')->get()->keyBy('userId');
        $logged = WorkingHour::whereHas('task', fn ($q) => $q->where('project_id', $projectId)->when($request->filled('sprintId'), fn ($x) => $x->where('sprint_id', $request->query('sprintId'))))->whereBetween('logged_date', [$from->toDateString(), $to->toDateString()])->when($request->filled('userId'), fn ($q) => $q->where('user_id', $request->query('userId')))->selectRaw('user_id userId, SUM(hours) loggedHours')->groupBy('user_id')->get()->keyBy('userId');

        return $estimated->keys()->merge($logged->keys())->unique()->map(fn ($id) => ['userId' => $id, 'estimatedHours' => (float) ($estimated[$id]->estimatedHours ?? 0), 'loggedHours' => (float) ($logged[$id]->loggedHours ?? 0)])->values()->all();
    }

    private function range(Request $request, int $days): array
    {
        $to = $request->filled('to') ? Carbon::parse($request->query('to'))->endOfDay() : now();
        $from = $request->filled('from') ? Carbon::parse($request->query('from'))->startOfDay() : $to->copy()->subDays($days);

        return [$from, $to];
    }

    private function filters(Builder $q, Request $request): void
    {
        if ($request->filled('userId')) {
            $q->where('assignee_id', $request->query('userId'));
        }
        if ($request->filled('sprintId')) {
            $q->where('sprint_id', $request->query('sprintId'));
        }
        foreach (['priority', 'type'] as $key) {
            $v = $request->query($key);
            if ($v) {
                $q->whereIn($key, is_array($v) ? $v : explode(',', $v));
            }
        }
    }
}
