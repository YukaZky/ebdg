<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Support\Facades\Route;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        then: function () {
            Route::get('/uploads/about/{filename}', function (string $filename) {
                $path = public_path('uploads/about/' . basename($filename));

                if (is_file($path)) {
                    return response()->file($path, [
                        'Cache-Control' => 'public, max-age=31536000',
                    ]);
                }

                return redirect(asset('assets/images/logo.png'));
            })->where('filename', '.*');
        },
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->alias([
        'admin' => \App\Http\Middleware\AuthAdmin::class,
    ]);
        $middleware->validateCsrfTokens(except: [
            'midtrans/notification',
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
     