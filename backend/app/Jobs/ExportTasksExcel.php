<?php

namespace App\Jobs;

use App\Models\Task;
use App\Services\NotificationService;
use App\Support\ExportStorage;
use App\Support\TaskFilters;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

/**
 * Queued Excel export of the (optionally filtered) task list. Ports the NestJS
 * `tasks-excel` Bull processor. Notifies the requester (export_ready) when done.
 */
class ExportTasksExcel implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        private readonly string $projectId,
        private readonly string $requesterId,
        private readonly array $filters,
    ) {}

    public function handle(NotificationService $notifications): void
    {
        ExportStorage::cleanupExpired();

        $query = Task::with(['assignee', 'reporter'])
            ->where('project_id', $this->projectId)
            ->whereNull('archived_at');
        TaskFilters::apply($query, $this->filters);
        $tasks = $query->orderBy('column_id')->orderBy('position')->limit(10000)->get();

        $fileName = 'tasks-'.$this->projectId.'-'.(int) (microtime(true) * 1000).'.xlsx';
        $this->writeWorkbook($tasks, ExportStorage::path($fileName));

        ExportStorage::notifyReady(
            $notifications,
            $this->projectId,
            $this->requesterId,
            $fileName,
            'Your task list export is ready to download',
        );
    }

    private function writeWorkbook($tasks, string $absPath): void
    {
        $spreadsheet = new Spreadsheet;
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Tasks');

        $headers = ['Title', 'Type', 'Status', 'Priority', 'Assignee', 'Reporter', 'Due date', 'Story points', 'Estimated hours', 'Logged hours'];
        $sheet->fromArray($headers, null, 'A1');
        $sheet->getStyle('A1:J1')->getFont()->setBold(true);

        $row = 2;
        foreach ($tasks as $task) {
            $sheet->fromArray([
                $task->title,
                $task->type,
                $task->status,
                $task->priority,
                $task->assignee?->full_name ?? $task->assignee?->email ?? '',
                $task->reporter?->full_name ?? $task->reporter?->email ?? '',
                $task->due_date ?? '',
                $task->story_points ?? '',
                $task->estimated_hours ?? '',
                $task->logged_hours ?? '',
            ], null, "A{$row}");
            $row++;
        }

        (new Xlsx($spreadsheet))->save($absPath);
        $spreadsheet->disconnectWorksheets();
    }
}
