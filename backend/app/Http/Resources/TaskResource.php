<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaskResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'projectId' => $this->project_id,
            'columnId' => $this->column_id,
            'sprintId' => $this->sprint_id,
            'title' => $this->title,
            'description' => $this->description,
            'note' => $this->note,
            'type' => $this->type,
            'priority' => $this->priority,
            'status' => $this->status,
            'assigneeId' => $this->assignee_id,
            'qaAssigneeId' => $this->qa_assignee_id,
            'reporterId' => $this->reporter_id,
            'assignee' => $this->assignee ? new TaskUserResource($this->assignee) : null,
            'qaAssignee' => $this->qaAssignee ? new TaskUserResource($this->qaAssignee) : null,
            'reporter' => $this->reporter ? new TaskUserResource($this->reporter) : null,
            'dueDate' => $this->due_date?->toDateString(),
            'estimatedHours' => $this->estimated_hours !== null ? (float) $this->estimated_hours : null,
            'loggedHours' => $this->logged_hours !== null ? (float) $this->logged_hours : null,
            'qaEstimatedHours' => $this->qa_estimated_hours !== null ? (float) $this->qa_estimated_hours : null,
            'qaLoggedHours' => $this->qa_logged_hours !== null ? (float) $this->qa_logged_hours : null,
            'position' => $this->position,
            'parentTaskId' => $this->parent_task_id,
            'parentTask' => $this->whenLoaded('parent', fn () => $this->parent ? [
                'id' => $this->parent->id,
                'title' => $this->parent->title,
                'status' => $this->parent->status,
                'taskNumber' => $this->parent->task_number,
                'position' => $this->parent->position,
                'parentTaskId' => $this->parent->parent_task_id,
            ] : null),
            'taskNumber' => $this->task_number,
            'columnName' => $this->whenLoaded('column', fn () => $this->column?->name),
            'columnColor' => $this->whenLoaded('column', fn () => $this->column?->color),
            'labels' => LabelResource::collection($this->whenLoaded('labels')),
            'requesters' => RequesterResource::collection($this->whenLoaded('requesters')),
            'subtasks' => TaskResource::collection($this->whenLoaded('subtasks')),
            'subtaskCount' => $this->whenLoaded('subtasks', fn () => $this->subtasks->count()),
            'doneSubtaskCount' => $this->whenLoaded('subtasks', fn () => $this->subtasks->where('status', 'done')->count()),
            'subtasksPreview' => $this->whenLoaded('subtasks', fn () => $this->subtasks->map(fn ($s) => [
                'id' => $s->id,
                'title' => $s->title,
                'status' => $s->status,
                'taskNumber' => $s->task_number,
                'assigneeId' => $s->assignee_id,
                'assignee' => $s->assignee ? new TaskUserResource($s->assignee) : null,
                'columnId' => $s->column_id,
                'columnName' => $s->relationLoaded('column') ? $s->column?->name : null,
                'columnColor' => $s->relationLoaded('column') ? $s->column?->color : null,
                'parentTaskId' => $s->parent_task_id,
            ])),
            'watcherCount' => $this->whenLoaded('watchers', fn () => $this->watchers->count()),
            'isWatching' => $this->whenLoaded('watchers', fn () => $this->watchers->contains('id', $request->user()?->id)),
            'createdAt' => $this->created_at?->toIso8601String(),
            'updatedAt' => $this->updated_at?->toIso8601String(),
            'project' => $this->whenLoaded('project', fn () => [
                'id' => $this->project->id,
                'name' => $this->project->name,
                'slug' => $this->project->slug,
            ]),
        ];
    }
}
