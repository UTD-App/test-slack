<?php

use Illuminate\Support\Facades\Route;
use Utd\Gifts\Http\Controllers\GiftController;

/*
| Gifts package API routes (read-side). The provider wraps these with
| prefix('api')->middleware('api'). `package.enabled:gifts` returns 403 while the
| package is disabled in admin/packages.
|
| NOTE: sending a gift has NO endpoint here — it happens through the host feature's
| route (e.g. POST /api/moment/{id}/gift) which resolves App\Contracts\GiftSender.
*/
Route::middleware(['auth:sanctum', 'package.enabled:gifts'])->group(function () {
    Route::get('gifts/categories', [GiftController::class, 'categories']);
    Route::get('gifts', [GiftController::class, 'index']);
    Route::get('gifts/history', [GiftController::class, 'history']);

    Route::get('gifts/context/{type}/{id}', [GiftController::class, 'contextGifts']);
    Route::get('gifts/context/{type}/{id}/gifters', [GiftController::class, 'contextGifters']);
});
