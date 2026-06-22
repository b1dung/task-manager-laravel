<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AttachmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'taskId' => $this->task_id,
            'uploaderId' => $this->uploader_id,
            'fileName' => $this->file_name,
            'fileUrl' => $this->file_url,
            'fileSize' => (int) $this->file_size,
            'mimeType' => $this->mime_type,
            'createdAt' => $this->created_at?->toIso8601String(),
        ];
    }
}
