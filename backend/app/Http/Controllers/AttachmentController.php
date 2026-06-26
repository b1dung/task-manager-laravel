<?php

namespace App\Http\Controllers;

use App\Events\ProjectEvent;
use App\Http\Resources\AttachmentResource;
use App\Http\Resources\ProjectAttachmentResource;
use App\Models\Attachment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AttachmentController extends Controller
{
    private const DISK = 'uploads';

    private const DIR = 'attachments';

    private const MAX_KB = 250 * 1024; // 250 MB

    public function index(string $projectId, string $taskId): JsonResponse
    {
        $attachments = Attachment::where('task_id', $taskId)->orderBy('created_at', 'desc')->get();

        return response()->ok(AttachmentResource::collection($attachments));
    }

    public function store(Request $request, string $projectId, string $taskId): JsonResponse
    {
        $request->validate(['file' => ['required', 'file', 'max:'.self::MAX_KB]]);

        $file = $request->file('file');
        $stored = Str::uuid().'.'.$file->getClientOriginalExtension();
        Storage::disk(self::DISK)->putFileAs(self::DIR, $file, $stored);

        $attachment = Attachment::create([
            'task_id' => $taskId,
            'uploader_id' => $request->user()->id,
            'file_name' => $file->getClientOriginalName(),
            'file_url' => '/uploads/'.self::DIR.'/'.$stored,
            'file_size' => $file->getSize(),
            'mime_type' => $file->getMimeType(),
        ]);

        ProjectEvent::dispatch($projectId, 'attachment:changed', ['taskId' => $taskId, 'attachmentId' => $attachment->id]);

        return response()->ok(new AttachmentResource($attachment), 201);
    }

    public function destroy(Request $request, string $projectId, string $taskId, string $id): JsonResponse
    {
        $attachment = Attachment::where('task_id', $taskId)->findOrFail($id);
        abort_unless($attachment->uploader_id === $request->user()->id, 403, 'You can only delete your own file');

        Storage::disk(self::DISK)->delete(self::DIR.'/'.basename($attachment->file_url));
        $attachment->delete();

        ProjectEvent::dispatch($projectId, 'attachment:changed', ['taskId' => $taskId, 'attachmentId' => $id]);

        return response()->ok(null);
    }

    public function download(string $projectId, string $taskId, string $id): StreamedResponse
    {
        $attachment = Attachment::where('task_id', $taskId)->findOrFail($id);
        $path = self::DIR.'/'.basename($attachment->file_url);
        abort_unless(Storage::disk(self::DISK)->exists($path), 404);

        return Storage::disk(self::DISK)->download($path, $attachment->file_name);
    }

    public function listForProject(string $projectId): JsonResponse
    {
        $attachments = Attachment::with(['uploader', 'task'])
            ->whereHas('task', fn ($q) => $q->where('project_id', $projectId))
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->ok(ProjectAttachmentResource::collection($attachments));
    }

    /** Stream by stored filename — for inline description images. */
    public function rawByName(string $projectId, string $filename): StreamedResponse
    {
        $att = Attachment::where('file_url', '/uploads/'.self::DIR.'/'.$filename)
            ->whereHas('task', fn ($q) => $q->where('project_id', $projectId))
            ->firstOrFail();

        $path = self::DIR.'/'.$filename;
        abort_unless(Storage::disk(self::DISK)->exists($path), 404);

        return Storage::disk(self::DISK)->response($path, $att->file_name);
    }
}
