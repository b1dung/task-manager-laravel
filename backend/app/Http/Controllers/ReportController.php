<?php

namespace App\Http\Controllers;

use App\Services\ReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function __construct(private readonly ReportService $reports) {}

    public function summary(string $projectId): JsonResponse
    {
        return response()->ok($this->reports->summary($projectId));
    }

    public function developer(Request $request, string $projectId): JsonResponse
    {
        return response()->ok($this->reports->developer($projectId, $request));
    }

    public function weekly(Request $request, string $projectId): JsonResponse
    {
        return response()->ok($this->reports->completions($projectId, $request, 7));
    }

    public function monthly(Request $request, string $projectId): JsonResponse
    {
        return response()->ok($this->reports->monthly($projectId, $request));
    }

    public function productivity(Request $request, string $projectId): JsonResponse
    {
        return response()->ok($this->reports->completions($projectId, $request, 30));
    }

    public function completionRate(Request $request, string $projectId): JsonResponse
    {
        return response()->ok($this->reports->completionRate($projectId, $request));
    }

    public function workingHours(Request $request, string $projectId): JsonResponse
    {
        return response()->ok($this->reports->workingHours($projectId, $request));
    }
}
