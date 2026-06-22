<?php

namespace App\Providers;

use Illuminate\Support\Facades\Response;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Success envelope: { "success": true, "data": ... }
        Response::macro('ok', function ($data = null, int $status = 200) {
            return Response::json(['success' => true, 'data' => $data], $status);
        });

        // Paginated envelope used by list endpoints (tasks, activity, ...).
        Response::macro('paginated', function ($items, int $page, int $limit, int $total) {
            return Response::json([
                'success' => true,
                'data' => $items,
                'meta' => [
                    'page' => $page,
                    'limit' => $limit,
                    'total' => $total,
                    'totalPages' => (int) ceil($total / max($limit, 1)),
                ],
            ]);
        });
    }
}
