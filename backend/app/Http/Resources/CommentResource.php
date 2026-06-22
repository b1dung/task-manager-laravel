<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CommentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'taskId' => $this->task_id,
            'authorId' => $this->author_id,
            'author' => $this->author ? new TaskUserResource($this->author) : null,
            'content' => $this->content,
            'parentId' => $this->parent_id,
            'editedAt' => $this->edited_at?->toIso8601String(),
            'createdAt' => $this->created_at?->toIso8601String(),
            'replies' => CommentResource::collection($this->whenLoaded('replies')),
        ];
    }
}
