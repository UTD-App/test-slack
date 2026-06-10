<?php

use App\Http\Controllers\PkController;
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
        Route::post('rooms/show-pk', [PkController::class, 'showPk']);
        Route::post('rooms/create-pk', [PkController::class, 'createPk']);
        Route::post('rooms/close-pk', [PkController::class, 'closePk']);
        Route::post('rooms/hide-pk', [PkController::class, 'hidePk']);
        Route::get('room-pk/{roomId}', [PkController::class, 'history']);
    });
});
