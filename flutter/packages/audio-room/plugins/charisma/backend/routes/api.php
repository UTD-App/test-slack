<?php

use App\Http\Controllers\CharismaController;
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
        Route::get('charisma/levels', [CharismaController::class, 'levels']);
        Route::get('charisma/room/{roomId}', [CharismaController::class, 'roomCharisma']);
        Route::post('charisma/change-status', [CharismaController::class, 'changeStatus']);
        Route::post('charisma/reset', [CharismaController::class, 'reset']);
    });
});
