<?php

namespace App\Http\Controllers;

use App\Events\ProjectEvent;
use App\Http\Resources\TaskResource;
use App\Models\Column;
use App\Models\ProjectTaskCounter;
use App\Models\Task;
use App\Models\WorkingHour;
use App\Services\ActivityService;
use App\Services\NotificationService;
use App\Support\TaskFilters;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TaskController extends Controller
{
    private const EAGER = ['assignee', 'qaAssignee', 'reporter', 'labels', 'requesters', 'subtasks.assignee', 'subtasks.column', 'parent'];

    public function __construct(private readonly ActivityService $activity, private readonly NotificationService $notifications) {}

    public function index(Request $request, string $projectId): JsonResponse
    {
        $page = max(1, (int) $request->query('page', 1));
        $limit = min(1000, max(1, (int) $request->query('limit', 50)));

        // Archived tasks are hidden from the board (kept, but not listed).
        $query = Task::with(self::EAGER)->where('project_id', $projectId)->whereNull('archived_at');
        TaskFilters::apply($query, $request->query());

        $total = (clone $query)->count();
        $tasks = $query->orderBy('column_id')->orderBy('position')
            ->forPage($page, $limit)->get();

        return response()->paginated(TaskResource::collection($tasks), $page, $limit, $total);
    }

    public function show(string $projectId, string $id): JsonResponse
    {
        $task = Task::with(self::EAGER)
            ->where('project_id', $projectId)->findOrFail($id);

        return response()->ok(new TaskResource($task));
    }

    public function store(Request $request, string $projectId): JsonResponse
    {
        $data = $request->validate([
            'columnId' => ['required', 'uuid'],
            'title' => ['required', 'string'],
            'description' => ['nullable', 'string'],
            'type' => ['nullable', 'in:bug,feature,task,story,epic'],
            'priority' => ['nullable', 'in:urgent,high,medium,low,lowest'],
            'assigneeId' => ['nullable', 'uuid'],
            'qaAssigneeId' => ['nullable', 'uuid'],
            'sprintId' => ['nullable', 'uuid'],
            'dueDate' => ['nullable', 'date'],
            'estimatedHours' => ['nullable', 'numeric', 'min:0'],
            'qaEstimatedHours' => ['nullable', 'numeric', 'min:0'],
            'parentTaskId' => ['nullable', 'uuid'],
            'labelIds' => ['nullable', 'array'],
            'requesterIds' => ['nullable', 'array'],
        ]);

        $column = Column::where('project_id', $projectId)->findOrFail($data['columnId']);

        $task = DB::transaction(function () use ($data, $projectId, $column, $request) {
            $counter = ProjectTaskCounter::lockForUpdate()->find($projectId)
                ?? ProjectTaskCounter::create(['project_id' => $projectId, 'last_number' => 0]);
            $counter->increment('last_number');

            $position = Task::where('column_id', $column->id)->count();

            $task = Task::create([
                'project_id' => $projectId,
                'column_id' => $column->id,
                'title' => $data['title'],
                'description' => $data['description'] ?? null,
                'type' => $data['type'] ?? 'task',
                'priority' => $data['priority'] ?? 'medium',
                'status' => Task::columnNameToStatus($column->name),
                'assignee_id' => $data['assigneeId'] ?? null,
                'qa_assignee_id' => $data['qaAssigneeId'] ?? null,
                'reporter_id' => $request->user()->id,
                'sprint_id' => $data['sprintId'] ?? null,
                'due_date' => $data['dueDate'] ?? null,
                'estimated_hours' => $data['estimatedHours'] ?? null,
                'qa_estimated_hours' => $data['qaEstimatedHours'] ?? null,
                'parent_task_id' => $data['parentTaskId'] ?? null,
                'position' => $position,
                'task_number' => $counter->last_number,
            ]);

            if (! empty($data['labelIds'])) {
                $task->labels()->sync($data['labelIds']);
            }
            if (! empty($data['requesterIds'])) {
                $task->requesters()->sync($data['requesterIds']);
            }

            return $task;
        });

        $this->activity->record($request, $projectId, 'created', 'task', $task->id, null, $this->snapshot($task));
        $this->notifications->taskEvent($projectId, $request->user()->id, 'task_created', 'task', $task->id, 'created task "'.$task->title.'"', [$task->assignee_id, $task->reporter_id]);
        ProjectEvent::dispatch($projectId, 'task:created', ['task' => (new TaskResource($task->load(self::EAGER)))->resolve()]);

        return response()->ok(new TaskResource($task->load(self::EAGER)), 201);
    }

    public function update(Request $request, string $projectId, string $id): JsonResponse
    {
        $data = $request->validate([
            'title' => ['nullable', 'string'],
            'description' => ['nullable', 'string'],
            'type' => ['nullable', 'in:bug,feature,task,story,epic'],
            'priority' => ['nullable', 'in:urgent,high,medium,low,lowest'],
            'status' => ['nullable', 'in:todo,in_progress,in_review,done'],
            'columnId' => ['nullable', 'uuid'],
            'assigneeId' => ['nullable', 'uuid'],
            'qaAssigneeId' => ['nullable', 'uuid'],
            'sprintId' => ['nullable', 'uuid'],
            'parentTaskId' => ['nullable', 'uuid'],
            'dueDate' => ['nullable', 'date'],
            'estimatedHours' => ['nullable', 'numeric', 'min:0'],
            'loggedHours' => ['nullable', 'numeric', 'min:0'],
            'qaEstimatedHours' => ['nullable', 'numeric', 'min:0'],
            'qaLoggedHours' => ['nullable', 'numeric', 'min:0'],
            'labelIds' => ['nullable', 'array'],
            'requesterIds' => ['nullable', 'array'],
        ]);

        $task = Task::where('project_id', $projectId)->findOrFail($id);
        $old = $this->snapshot($task);

        // Moving to a column is the canonical way to change "status".
        if (! empty($data['columnId']) && $data['columnId'] !== $task->column_id) {
            $this->moveToColumn($task, $data['columnId'], null);
        } elseif (! empty($data['status'])) {
            $task->status = $data['status'];
        }

        foreach ([
            'title' => 'title', 'description' => 'description', 'type' => 'type',
            'priority' => 'priority', 'assigneeId' => 'assignee_id', 'qaAssigneeId' => 'qa_assignee_id',
            'sprintId' => 'sprint_id',
            'parentTaskId' => 'parent_task_id', 'dueDate' => 'due_date',
            'estimatedHours' => 'estimated_hours', 'loggedHours' => 'logged_hours',
            'qaEstimatedHours' => 'qa_estimated_hours', 'qaLoggedHours' => 'qa_logged_hours',
        ] as $in => $col) {
            if ($request->has($in)) {
                $task->{$col} = $data[$in] ?? null;
            }
        }

        $task->save();

        if ($request->has('labelIds')) {
            $task->labels()->sync($data['labelIds'] ?? []);
        }

        if ($request->has('requesterIds')) {
            $task->requesters()->sync($data['requesterIds'] ?? []);
        }

        $new = $this->snapshot($task);
        $action = $old['assigneeId'] !== $new['assigneeId'] ? 'assigned' : ($old['status'] !== $new['status'] ? 'status_changed' : 'updated');
        $this->activity->record($request, $projectId, $action, 'task', $task->id, $old, $new);
        $type = $action === 'assigned' ? 'task_assigned' : 'task_updated';
        $this->notifications->taskEvent($projectId, $request->user()->id, $type, 'task', $task->id, 'updated task "'.$task->title.'"', [$task->assignee_id, $task->qa_assignee_id, $task->reporter_id]);
        ProjectEvent::dispatch($projectId, 'task:updated', ['task' => (new TaskResource($task->fresh(self::EAGER)))->resolve()]);

        return response()->ok(new TaskResource($task->fresh(self::EAGER)));
    }

    public function move(Request $request, string $projectId, string $id): JsonResponse
    {
        $data = $request->validate([
            'columnId' => ['required', 'uuid'],
            'position' => ['required', 'integer', 'min:0'],
        ]);

        $task = Task::where('project_id', $projectId)->findOrFail($id);
        $old = $this->snapshot($task);
        $this->moveToColumn($task, $data['columnId'], $data['position']);
        $task->save();

        $this->activity->record($request, $projectId, 'moved', 'task', $task->id, $old, $this->snapshot($task));
        $this->notifications->taskEvent($projectId, $request->user()->id, 'task_moved', 'task', $task->id, 'moved task "'.$task->title.'"', [$task->assignee_id, $task->reporter_id]);
        ProjectEvent::dispatch($projectId, 'task:moved', ['taskId' => $task->id, 'projectId' => $projectId, 'fromColumnId' => $old['columnId'], 'toColumnId' => $task->column_id, 'position' => $task->position]);

        return response()->ok(new TaskResource($task->fresh(self::EAGER)));
    }

    public function destroy(Request $request, string $projectId, string $id): JsonResponse
    {
        $task = Task::where('project_id', $projectId)->findOrFail($id);
        $old = $this->snapshot($task);
        $task->delete();
        $this->activity->record($request, $projectId, 'deleted', 'task', $id, $old);
        ProjectEvent::dispatch($projectId, 'task:deleted', ['taskId' => $id, 'projectId' => $projectId]);

        return response()->ok(null);
    }

    public function archive(Request $request, string $projectId, string $id): JsonResponse
    {
        $task = Task::where('project_id', $projectId)->findOrFail($id);
        $task->update(['archived_at' => now(), 'archived_by' => $request->user()->id]);

        ProjectEvent::dispatch($projectId, 'task:updated', ['task' => (new TaskResource($task->fresh(self::EAGER)))->resolve()]);

        return response()->ok(new TaskResource($task->fresh(self::EAGER)));
    }

    public function unarchive(string $projectId, string $id): JsonResponse
    {
        $task = Task::where('project_id', $projectId)->findOrFail($id);
        $task->update(['archived_at' => null, 'archived_by' => null]);

        ProjectEvent::dispatch($projectId, 'task:updated', ['task' => (new TaskResource($task->fresh(self::EAGER)))->resolve()]);

        return response()->ok(new TaskResource($task->fresh(self::EAGER)));
    }

    public function restore(string $projectId, string $id): JsonResponse
    {
        $task = Task::withTrashed()->where('project_id', $projectId)->findOrFail($id);
        $task->restore();

        ProjectEvent::dispatch($projectId, 'task:updated', ['task' => (new TaskResource($task->fresh(self::EAGER)))->resolve()]);

        return response()->ok(new TaskResource($task->fresh(self::EAGER)));
    }

    public function logTime(Request $request, string $projectId, string $id): JsonResponse
    {
        $data = $request->validate([
            'hours' => ['required', 'numeric', 'gt:0'],
            'loggedDate' => ['nullable', 'date'],
            'description' => ['nullable', 'string'],
            'isQa' => ['nullable', 'boolean'],
        ]);
        $task = Task::where('project_id', $projectId)->findOrFail($id);
        $isQa = (bool) ($data['isQa'] ?? false);
        $column = $isQa ? 'qa_logged_hours' : 'logged_hours';
        $task->{$column} = max(0, (float) $task->{$column} + (float) $data['hours']);
        $task->save();

        WorkingHour::create(['task_id' => $task->id, 'user_id' => $request->user()->id, 'hours' => $data['hours'], 'is_qa' => $isQa, 'logged_date' => $data['loggedDate'] ?? now()->toDateString(), 'note' => $data['description'] ?? null]);
        // Record the amount just logged (not the running total) + whether it's QA, so the
        // history can show "logged 2h" instead of a bare "updated". The `action` column is
        // a fixed enum, so we stay on 'updated' and let the FE recognise a time-log entry
        // by these newValues keys (hours/isQa).
        $this->activity->record($request, $projectId, 'updated', 'task', $task->id, null, [
            'hours' => (float) $data['hours'],
            'isQa' => $isQa,
            'note' => $data['description'] ?? null,
            ($isQa ? 'qaLoggedHours' : 'loggedHours') => (float) $task->{$column},
        ]);
        $this->notifications->taskEvent($projectId, $request->user()->id, 'time_logged', 'task', $task->id, ($isQa ? 'logged QA time on "' : 'logged time on "').$task->title.'"', [$task->assignee_id, $task->qa_assignee_id, $task->reporter_id]);
        ProjectEvent::dispatch($projectId, 'task:updated', ['task' => (new TaskResource($task->fresh(self::EAGER)))->resolve()]);

        return response()->ok(new TaskResource($task->fresh(self::EAGER)));
    }

    /** Sets column + position + re-derives status from the column name. */
    private function moveToColumn(Task $task, string $columnId, ?int $position): void
    {
        $column = Column::where('project_id', $task->project_id)->findOrFail($columnId);
        $task->column_id = $column->id;
        $task->status = Task::columnNameToStatus($column->name);
        $task->position = $position ?? Task::where('column_id', $column->id)->count();
    }


    private function snapshot(Task $task): array
    {
        return ['title' => $task->title, 'status' => $task->status, 'columnId' => $task->column_id, 'assigneeId' => $task->assignee_id, 'priority' => $task->priority, 'dueDate' => $task->due_date?->format('Y-m-d')];
    }
}
