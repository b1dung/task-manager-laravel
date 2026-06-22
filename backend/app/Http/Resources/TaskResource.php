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
            'type' => $this->type,
            'priority' => $this->priority,
            'status' => $this->status,
            'assigneeId' => $this->assignee_id,
            'reporterId' => $this->reporter_id,
            'assignee' => $this->assignee ? new TaskUserResource($this->assignee) : null,
            'reporter' => $this->reporter ? new TaskUserResource($this->reporter) : null,
            'dueDate' => $this->due_date?->toDateString(),
            'estimatedHours' => $this->estimated_hours !== null ? (float) $this->estimated_hours : null,
            'loggedHours' => $this->logged_hours !== null ? (float) $this->logged_hours : null,
            'storyPoints' => $this->story_points,
            'position' => $this->position,
            'parentTaskId' => $this->parent_task_id,
            'taskNumber' => $this->task_number,
            'labels' => LabelResource::collection($this->whenLoaded('labels')),
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
                'parentTaskId' => $s->parent_task_id,
            ])),
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
