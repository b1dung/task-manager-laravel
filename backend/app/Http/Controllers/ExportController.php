<?php

namespace App\Http\Controllers;

use App\Jobs\ExportMonthlyReportPdf;
use App\Jobs\ExportTasksExcel;
use App\Models\Project;
use App\Models\Task;
use App\Support\ExportStorage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
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

    /**
     * GET /projects/{projectId}/export/tasks/xlsx?from=&to=&baseUrl=
     *
     * Synchronous styled Excel (.xlsx) download (no queue) of tasks created in
     * the [from, to] window. Column layout mirrors the legacy Export.xls; time
     * columns are formatted like "22.5h", blank when zero. Styling:
     * green bold header, zebra-striped rows, auto-sized columns, real clickable
     * hyperlinks on the Link task / Task parent columns.
     */
    public function tasksXlsx(Request $request, string $projectId): StreamedResponse
    {
        $data = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date'],
            'baseUrl' => ['nullable', 'string'],
        ]);

        $project = Project::findOrFail($projectId);
        $key = $this->projectKey($project->name);
        // SPA base URL so the link columns deep-link to each task. The FE sends
        // its own origin; fall back to the configured frontend URL.
        $base = rtrim($data['baseUrl'] ?? (string) config('app.frontend_url'), '/');
        // Timestamps are stored in UTC; render them in the site-wide timezone.
        $tz = \App\Models\AppSetting::get('timezone', config('app.timezone'));

        $query = Task::with(['assignee', 'qaAssignee', 'requesters', 'labels', 'column', 'parent'])
            ->where('project_id', $projectId)
            ->whereNull('archived_at');
        if (! empty($data['from'])) {
            $query->where('created_at', '>=', $data['from'].' 00:00:00');
        }
        if (! empty($data['to'])) {
            $query->where('created_at', '<=', $data['to'].' 23:59:59');
        }
        $tasks = $query->orderBy('created_at', 'desc')->limit(10000)->get();

        $headers = [
            'Created', 'Updated', 'Link task', 'Task parent', 'Task type',
            'Month', 'Status', 'Requester', 'Company', 'Assignee', 'QA Assignee', 'Title',
            '請求工数', '実装内容', 'メモ', 'Note', 'Time tracking', 'QA time tracking', 'Total time',
        ];
        $lastCol = 'S'; // 19 columns A..S

        $spreadsheet = new Spreadsheet;
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Export');
        $sheet->fromArray($headers, null, 'A1');

        $rowNum = 2;
        foreach ($tasks as $i => $t) {
            $isSub = $t->parent_task_id !== null;
            $created = $t->created_at?->copy()->setTimezone($tz);
            $updated = $t->updated_at?->copy()->setTimezone($tz);
            $loggedH = (float) $t->logged_hours;
            $qaH = (float) $t->qa_logged_hours;
            $linkLabel = $t->task_number !== null ? $key.'-'.$t->task_number : '';
            $parentLabel = ($t->parent && $t->parent->task_number !== null) ? $key.'-'.$t->parent->task_number : '';

            $sheet->fromArray([
                $created?->format('Y-m-d H:i:s') ?? '',
                $updated?->format('Y-m-d H:i:s') ?? '',
                $linkLabel,
                $parentLabel,
                $isSub ? 'sub task' : 'task',
                $isSub ? '' : ($created?->format('n') ?? ''),
                $t->column?->name ?? $t->status,
                $t->requesters->pluck('name')->implode(', '),
                $t->labels->pluck('name')->implode(', '),
                $t->assignee?->full_name ?? $t->assignee?->email ?? '',
                $t->qaAssignee?->full_name ?? $t->qaAssignee?->email ?? '',
                $t->title,
                '', '', '', '', // 請求工数 / 実装内容 / メモ / Note
                $this->formatDuration($loggedH),
                $this->formatDuration($qaH),
                $this->formatDuration($loggedH + $qaH),
            ], null, "A{$rowNum}");

            // Real clickable hyperlinks on the link columns.
            if ($linkLabel !== '') {
                $sheet->getCell("C{$rowNum}")->getHyperlink()->setUrl($base.'/projects/'.$projectId.'/tasks?selectedIssue='.$t->id);
            }
            if ($parentLabel !== '') {
                $sheet->getCell("D{$rowNum}")->getHyperlink()->setUrl($base.'/projects/'.$projectId.'/tasks?selectedIssue='.$t->parent->id);
            }

            // Zebra striping: 1st data row is "odd".
            $fillColor = ($i % 2 === 0) ? 'E7F9EF' : 'FFFFFF';
            $sheet->getStyle("A{$rowNum}:{$lastCol}{$rowNum}")->getFill()
                ->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB($fillColor);

            $rowNum++;
        }

        $lastRow = $rowNum - 1;

        // Header style: bold, green background.
        $sheet->getStyle("A1:{$lastCol}1")->getFont()->setBold(true);
        $sheet->getStyle("A1:{$lastCol}1")->getFill()
            ->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB('63D297');

        // Make the link columns look like links (blue, underlined).
        if ($lastRow >= 2) {
            $sheet->getStyle("C2:D{$lastRow}")->getFont()->setUnderline(true)->getColor()->setRGB('0B5FFF');
        }

        // Thin borders (Excel default colour) around every used cell.
        $sheet->getStyle("A1:{$lastCol}{$lastRow}")->getBorders()->getAllBorders()
            ->setBorderStyle(Border::BORDER_THIN);

        // Minimum row height of 25px (Excel measures height in points: 25px ≈ 18.75pt).
        $sheet->getDefaultRowDimension()->setRowHeight(18.75);

        // Vertically centre all cell content, top-align/left wrap kept default.
        $sheet->getStyle("A1:{$lastCol}{$lastRow}")->getAlignment()
            ->setVertical(Alignment::VERTICAL_CENTER);

        // Horizontally centre the time columns (Q=Time, R=QA time, S=Total).
        $sheet->getStyle("Q1:S{$lastRow}")->getAlignment()
            ->setHorizontal(Alignment::HORIZONTAL_CENTER);

        // Auto-size every column to fit its content.
        foreach (range('A', $lastCol) as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }
        $sheet->freezePane('A2'); // keep header visible while scrolling

        $fileName = 'tasks-export-'.($data['from'] ?? 'all').'_'.($data['to'] ?? 'now').'-'.now()->format('Ymd-His').'.xlsx';

        return response()->streamDownload(function () use ($spreadsheet) {
            (new Xlsx($spreadsheet))->save('php://output');
            $spreadsheet->disconnectWorksheets();
        }, $fileName, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    /** Formats decimal hours as "22.5h"; empty when zero. */
    private function formatDuration(float $hours): string
    {
        if ($hours <= 0) {
            return '';
        }

        return rtrim(rtrim(number_format($hours, 2, '.', ''), '0'), '.').'h';
    }

    /** Mirrors the frontend getProjectKey(): initials for multi-word names, else first 5 chars. */
    private function projectKey(?string $name): string
    {
        $words = preg_split('/\s+/', trim((string) $name), -1, PREG_SPLIT_NO_EMPTY) ?: [];
        if (count($words) > 1) {
            return mb_strtoupper(implode('', array_map(fn ($w) => mb_substr($w, 0, 1), $words)));
        }

        return mb_strtoupper(mb_substr($words[0] ?? 'TASK', 0, 5));
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
