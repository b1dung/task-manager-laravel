<?php

namespace App\Jobs;

use App\Services\NotificationService;
use App\Services\ReportService;
use App\Support\ExportStorage;
use Dompdf\Dompdf;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Http\Request;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Queued PDF export of the monthly report. Ports the NestJS
 * `monthly-report-pdf` Bull processor. Notifies the requester when done.
 */
class ExportMonthlyReportPdf implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        private readonly string $projectId,
        private readonly string $requesterId,
        private readonly array $query,
    ) {}

    public function handle(ReportService $reports, NotificationService $notifications): void
    {
        ExportStorage::cleanupExpired();

        $request = new Request($this->query);
        $kpi = $reports->monthly($this->projectId, $request);
        $completionRate = $reports->completionRate($this->projectId, $request);

        $fileName = 'monthly-report-'.$this->projectId.'-'.(int) (microtime(true) * 1000).'.pdf';
        $this->writePdf($this->projectId, $kpi, $completionRate, ExportStorage::path($fileName));

        ExportStorage::notifyReady(
            $notifications,
            $this->projectId,
            $this->requesterId,
            $fileName,
            'Your monthly report export is ready to download',
        );
    }

    private function writePdf(string $projectId, array $kpi, array $completionRate, string $absPath): void
    {
        $rows = '';
        foreach ($completionRate as $slice) {
            $rows .= '<tr><td>'.e($slice['status']).'</td><td>'.e((string) $slice['count']).'</td></tr>';
        }

        $html = <<<HTML
        <html><body style="font-family: DejaVu Sans, sans-serif; font-size: 11px;">
            <h1 style="text-align:center;">Monthly Report</h1>
            <p><strong>Project:</strong> {$projectId}</p>
            <p><strong>Period:</strong> {$kpi['from']} – {$kpi['to']}</p>
            <h3 style="text-decoration:underline;">KPI summary</h3>
            <p>Target tasks: {$kpi['target']}<br>
               Completed tasks: {$kpi['actual']}<br>
               Completion rate: {$kpi['completionRate']}%</p>
            <h3 style="text-decoration:underline;">Completion by status</h3>
            <table><tbody>{$rows}</tbody></table>
        </body></html>
        HTML;

        $dompdf = new Dompdf;
        $dompdf->loadHtml($html);
        $dompdf->setPaper('A4');
        $dompdf->render();
        file_put_contents($absPath, $dompdf->output());
    }
}
