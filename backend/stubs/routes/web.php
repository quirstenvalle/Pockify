<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'app' => 'Pockify API',
        'status' => 'ok',
        'docs' => '/api',
    ]);
});
