<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaskLinkResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'sourceTaskId' => $this->source_task_id,
            'targetTaskId' => $this->target_task_id,
            'linkType' => $this->link_type,
            'sourceTask' => $this->whenLoaded('source', fn () => new TaskResource($this->source)),
            'targetTask' => $this->whenLoaded('target', fn () => new TaskResource($this->target)),
        ];
    }
}
