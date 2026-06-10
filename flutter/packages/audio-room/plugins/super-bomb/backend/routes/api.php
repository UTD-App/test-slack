<?php

use App\Http\Controllers\SuperBombController;
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
        Route::get('boom_levels/get_videos', [SuperBombController::class, 'videos']);
        Route::get('boom_levels/{roomId}', [SuperBombController::class, 'levels']);
        Route::get('room-boom/themes', [SuperBombController::class, 'themes']);
        Route::get('super-boom-rules', [SuperBombController::class, 'rules']);
    });
});
