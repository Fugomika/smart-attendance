<?php

use App\Http\Middleware\EnsureAdmin;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        apiPrefix: 'api',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'admin' => EnsureAdmin::class,
        ]);

        $middleware->redirectGuestsTo(function (Request $request) {
            if (str_starts_with($request->path(), 'api/')) {
                return null;
            }

            return '/admin/login';
        });
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(function (Request $request) {
            return str_starts_with($request->path(), 'api/') || $request->expectsJson();
        });

        $exceptions->render(function (ValidationException $e, Request $request) {
            if (str_starts_with($request->path(), 'api/') || $request->expectsJson()) {
                return response()->json([
                    'message' => 'Validation failed',
                    'errors' => collect($e->errors())
                        ->flatMap(fn ($msgs, $field) => collect($msgs)->map(fn ($msg) => ['path' => $field, 'message' => $msg]))
                        ->values(),
                ], 422);
            }
        });

        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if (str_starts_with($request->path(), 'api/') || $request->expectsJson()) {
                return response()->json(['message' => 'Unauthorized'], 401);
            }
        });

        $exceptions->render(function (ModelNotFoundException $e, Request $request) {
            if (str_starts_with($request->path(), 'api/') || $request->expectsJson()) {
                return response()->json(['message' => 'Not found'], 404);
            }
        });
    })->create();
