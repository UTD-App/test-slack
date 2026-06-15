<?php

use Illuminate\Support\Facades\Route;
use Utd\AudioRoom\Http\Controllers\CharismaController;
use Utd\AudioRoom\Http\Controllers\RoomController;
use Utd\AudioRoom\Http\Controllers\RoomAdminController;

// UTD Stream webhook — no auth (called by external service, not a user)
Route::post('webhook/stream', [RoomController::class, 'streamWebhook']);

Route::middleware(['auth:sanctum', 'package.enabled:audio-room'])->group(function () {
    // Room CRUD
    Route::get('rooms', [RoomController::class, 'index']);
    Route::post('rooms', [RoomController::class, 'store']);
    Route::get('rooms/mine', [RoomController::class, 'mine']);
    Route::get('rooms/categories', [RoomController::class, 'categories']);
    Route::get('rooms/categories/{id}/types', [RoomController::class, 'categoryTypes']);
    Route::get('rooms/{id}', [RoomController::class, 'show']);
    Route::put('rooms/{id}', [RoomController::class, 'update']);
    Route::delete('rooms/{id}', [RoomController::class, 'destroy']);

    // Room actions
    Route::post('rooms/{id}/enter', [RoomController::class, 'enter']);
    Route::post('rooms/{id}/exit', [RoomController::class, 'exit']);
    Route::post('rooms/{id}/favorite', [RoomController::class, 'toggleFavorite']);
    Route::post('rooms/{id}/comment-status', [RoomController::class, 'toggleComments']);
    Route::post('rooms/{id}/mode', [RoomController::class, 'changeMode']);
    Route::post('rooms/{id}/remove-password', [RoomController::class, 'removePassword']);
    Route::post('rooms/{id}/mute-writing', [RoomController::class, 'muteWriting']);
    Route::post('rooms/{id}/unmute-writing', [RoomController::class, 'unmuteWriting']);
    Route::post('rooms/{id}/yellow-banner', [RoomController::class, 'sendBanner']);
    Route::get('rooms/{id}/users', [RoomController::class, 'users']);
    Route::get('rooms/{id}/ranking', [RoomController::class, 'ranking']);
    Route::get('config/room', [RoomController::class, 'config']);

    // Admin & Blacklist
    Route::get('rooms/{id}/admins', [RoomAdminController::class, 'index']);
    Route::post('rooms/{id}/admins', [RoomAdminController::class, 'store']);
    Route::delete('rooms/{roomId}/admins/{userId}', [RoomAdminController::class, 'destroy']);
    Route::get('rooms/{id}/blacklist', [RoomAdminController::class, 'blacklist']);
    Route::post('rooms/{id}/kick', [RoomAdminController::class, 'kick']);
    Route::post('rooms/{id}/ban', [RoomAdminController::class, 'ban']);
    Route::delete('rooms/{roomId}/blacklist/{userId}', [RoomAdminController::class, 'unban']);
    Route::post('rooms/{id}/check-role', [RoomAdminController::class, 'checkRole']);

    // Charisma
    Route::get('charisma/levels', [CharismaController::class, 'levels']);
    Route::get('charisma/room/{roomId}', [CharismaController::class, 'roomCharisma']);
    Route::get('charisma/status/{roomId}', [CharismaController::class, 'status']);
    Route::post('charisma/change-status', [CharismaController::class, 'changeStatus']);
    Route::post('charisma/reset', [CharismaController::class, 'reset']);
});
