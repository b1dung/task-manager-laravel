<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProjectAttachmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'taskId' => $this->task_id,
            'fileName' => $this->file_name,
            'fileUrl' => $this->file_url,
            'fileSize' => (int) $this->file_size,
            'mimeType' => $this->mime_type,
            'createdAt' => $this->created_at?->toIso8601String(),
            'uploaderId' => $this->uploader_id,
            'uploader' => $this->uploader ? [
                'id' => $this->uploader->id,
                'fullName' => $this->uploader->full_name,
                'avatarUrl' => $this->uploader->avatar_url,
            ] : null,
            'task' => $this->task ? [
                'id' => $this->task->id,
                'title' => $this->task->title,
                'taskNumber' => $this->task->task_number,
            ] : null,
        ];
    }
}
