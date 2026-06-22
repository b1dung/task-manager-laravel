<?php

use App\Http\Middleware\EnsurePermission;
use App\Http\Middleware\SecurityHeaders;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Sentry\Laravel\Integration;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        apiPrefix: 'api/v1',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->append(SecurityHeaders::class);
        $middleware->alias([
            'permission' => EnsurePermission::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        Integration::handles($exceptions);

        // Treat all /api/* requests as JSON so auth failures return 401 JSON
        // (never an HTML redirect to a non-existent `login` route).
        $exceptions->shouldRenderJsonWhen(fn (Request $request) => $request->is('api/*'));

        // Every API error returns the contract the React frontend expects:
        //   { "success": false, "message": <string|string[]> }
        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/*')) {
                return null; // keep default rendering for non-API routes
            }

            if ($e instanceof ValidationException) {
                return response()->json([
                    'success' => false,
                    'message' => collect($e->errors())->flatten()->values()->all(),
                ], 422);
            }

            if ($e instanceof AuthenticationException) {
                return response()->json(['success' => false, 'message' => 'Unauthenticated'], 401);
            }

            $status = $e instanceof HttpExceptionInterface ? $e->getStatusCode() : 500;
            $message = $e->getMessage() ?: 'Server error';
            if ($status >= 500 && ! config('app.debug')) {
                $message = 'Server error';
            }

            return response()->json(['success' => false, 'message' => $message], $status);
        });
    })->create();
