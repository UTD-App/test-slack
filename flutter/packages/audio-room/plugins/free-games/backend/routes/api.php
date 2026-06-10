<?php

use App\Http\Controllers\FreeGamesController;
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
        Route::get('free-games/images', [FreeGamesController::class, 'images']);
    });
});
