<?php

use App\Http\Controllers\EmojiController;
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
        Route::get('emojis/categories', [EmojiController::class, 'categories']);
        Route::get('emojis', [EmojiController::class, 'index']);
        Route::get('emojis/{id}', [EmojiController::class, 'show']);
    });
});
