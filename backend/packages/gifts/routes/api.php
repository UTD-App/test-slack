<?php

use Illuminate\Support\Facades\Route;
use Utd\Gifts\Http\Controllers\GiftController;

/*
| Gifts package API routes. The provider wraps these with
| prefix('api')->middleware('api'). `package.enabled:gifts` returns 403 while the
| package is disabled in admin/packages.
|
| POST /gifts/send mirrors Eagle's gift_queue_cp (multi-receiver send) on top of
| the App\Contracts\GiftSender contract. Gifts can also be sent through a host
| feature's own route (e.g. POST /api/moment/{id}/gift) which resolves the same
| contract; room-specific effects are layered by GiftSent listeners.
*/
Route::middleware(['auth:sanctum', 'package.enabled:gifts'])->group(function () {
    // Static segments first so they aren't shadowed by param routes below.
    Route::get('gifts/categories', [GiftController::class, 'categories']);
    Route::get('gifts/history', [GiftController::class, 'history']);
    Route::get('gifts/images', [GiftController::class, 'images']);          // Eagle parity
    Route::get('gifts/v2', [GiftController::class, 'indexV2']);             // Eagle parity (?type=)
    Route::get('gift-categories', [GiftController::class, 'categories']);   // Eagle alias
    Route::get('gifts-by-id', [GiftController::class, 'byId']);             // Eagle parity (?id=)
    Route::get('user-gifts', [GiftController::class, 'userGifts']);         // Eagle parity (affordable)
    Route::get('my_gifts', [GiftController::class, 'myGifts']);             // Eagle parity (?user_id=)

    Route::get('gifts', [GiftController::class, 'index']);

    Route::post('gifts/send', [GiftController::class, 'send']);             // Eagle parity (gift_queue_cp)

    Route::get('gifts/context/{type}/{id}', [GiftController::class, 'contextGifts']);
    Route::get('gifts/context/{type}/{id}/gifters', [GiftController::class, 'contextGifters']);
});
