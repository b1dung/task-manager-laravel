<?php

namespace App\Http\Controllers;

use App\Jobs\ExportMonthlyReportPdf;
use App\Jobs\ExportTasksExcel;
use App\Support\ExportStorage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Queued exports (ported from the NestJS export module). Excel/PDF are generated
 * on the queue; a notification with the download link is sent when ready.
 * All routes require `view_reports`.
 */
class ExportController extends Controller
{
    /** POST /projects/{projectId}/export/tasks/excel */
    public function tasksExcel(Request $request, string $projectId): JsonResponse
    {
        ExportTasksExcel::dispatch($projectId, $request->user()->id, $request->query());

        return response()->ok(['jobId' => (string) Str::uuid()], 202);
    }

    /** POST /projects/{projectId}/export/reports/monthly/pdf */
    public function monthlyReportPdf(Request $request, string $projectId): JsonResponse
    {
        ExportMonthlyReportPdf::dispatch($projectId, $request->user()->id, $request->query());

        return response()->ok(['jobId' => (string) Str::uuid()], 202);
    }

    /** GET /projects/{projectId}/export/files/{fileName} */
    public function download(string $projectId, string $fileName): StreamedResponse
    {
        $safeName = basename($fileName);
        abort_if($safeName !== $fileName || ! str_contains($safeName, $projectId), 400, 'Invalid export file');

        $disk = Storage::disk(ExportStorage::DISK);
        $path = ExportStorage::DIR.'/'.$safeName;
        abort_unless($disk->exists($path), 404);

        return $disk->download($path, $safeName, ['X-Content-Type-Options' => 'nosniff']);
    }
}
