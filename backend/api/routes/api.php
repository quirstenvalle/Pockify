<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\FinanceController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes (Laravel 9 / XAMPP MySQL)
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/email/verify', [AuthController::class, 'verifyEmail']);
Route::post('/email/resend', [AuthController::class, 'resendCode']);
Route::post('/email/change', [AuthController::class, 'changeEmail']);
Route::get('/email/status', [AuthController::class, 'emailStatus']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/finance', [FinanceController::class, 'index']);
    Route::post('/budgets', [FinanceController::class, 'storeBudget']);
    Route::delete('/budgets/{budget}', [FinanceController::class, 'destroyBudget']);
    Route::post('/savings-goals', [FinanceController::class, 'storeGoal']);
    Route::post('/savings-goals/{goal}/contributions', [FinanceController::class, 'contribute']);
});
