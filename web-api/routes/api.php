<?php

use App\Http\Controllers\Admin\AttendanceController as AdminAttendanceController;
use App\Http\Controllers\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Admin\OfficeController as AdminOfficeController;
use App\Http\Controllers\Admin\UserController as AdminUserController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\FileController;
use App\Http\Controllers\OfficeController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/mobile/login', [AuthController::class, 'mobileLogin']);
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::patch('/users/{id}', [UserController::class, 'update']);
        Route::patch('/users/{id}/password', [UserController::class, 'updatePassword']);

        Route::post('/files', [FileController::class, 'upload']);
        Route::get('/files/{id}', [FileController::class, 'show']);

        Route::get('/offices/active', [OfficeController::class, 'active']);

        Route::get('/attendances/today', [AttendanceController::class, 'today']);
        Route::get('/attendances/history', [AttendanceController::class, 'history']);
        Route::post('/attendances/clock-in', [AttendanceController::class, 'clockIn']);
        Route::post('/attendances/clock-out', [AttendanceController::class, 'clockOut']);
        Route::get('/attendances/{id}', [AttendanceController::class, 'show']);

        Route::prefix('admin')->middleware('admin')->group(function () {
            Route::get('/dashboard/summary', [AdminDashboardController::class, 'summary']);

            Route::get('/users', [AdminUserController::class, 'index']);
            Route::get('/users/{id}', [AdminUserController::class, 'show']);

            Route::get('/attendances', [AdminAttendanceController::class, 'index']);
            Route::get('/attendances/report', [AdminAttendanceController::class, 'report']);
            Route::patch('/attendances/{id}/validation', [AdminAttendanceController::class, 'validateAttendance']);
            Route::get('/attendances/{id}', [AdminAttendanceController::class, 'show']);

            Route::patch('/offices/{id}', [AdminOfficeController::class, 'update']);
        });
    });
});
