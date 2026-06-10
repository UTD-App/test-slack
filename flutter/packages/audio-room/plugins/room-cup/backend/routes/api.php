<?php

use App\Http\Controllers\RoomCupController;
use Illuminate\Support\Facades\Route;

Route::prefix(config('app.api_prefix'))->group(function () {
    Route::middleware([
        'auth:sanctum',
        'checkLatestToken',
        'generalBan',
        'userBan',
        'update.last.seen',
        'localization',
    ])->group(function () {
        Route::prefix('room-cup')->group(function () {
            Route::get('report/{roomId}', [RoomCupController::class, 'myReward']);
            Route::get('history/{roomId}', [RoomCupController::class, 'history']);
            Route::get('cup-target', [RoomCupController::class, 'cupTarget']);
        });
    });
});
