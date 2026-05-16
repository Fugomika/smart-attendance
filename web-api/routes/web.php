<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Ensure api routes are loaded in this project
if (file_exists(base_path('routes/api.php'))) {
    Route::prefix('api')->middleware('api')->group(base_path('routes/api.php'));
}
