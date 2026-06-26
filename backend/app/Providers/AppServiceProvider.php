<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
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
        // Login is throttled PER ACCOUNT (email), not per IP — so an entire office
        // behind one shared/NAT IP can all sign in at the same time without hitting
        // a shared queue, while brute-forcing a single account stays limited.
        RateLimiter::for('login', function (Request $request) {
            $email = strtolower(trim((string) $request->input('email')));

            return Limit::perMinute(5)->by('login|'.$email.'|'.$request->ip());
        });

        // Token refresh is keyed by the per-session refresh cookie (fallback: IP), so
        // many clients on the same office IP don't share one bucket when the app loads.
        RateLimiter::for('refresh', function (Request $request) {
            $key = $request->cookie('refresh_token') ?: $request->ip();

            return Limit::perMinute(30)->by('refresh|'.sha1((string) $key));
        });

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
