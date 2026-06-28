<?php

use Illuminate\Support\Facades\Route;
use Utd\Reels\Http\Controllers\RealsController;
use Utd\Reels\Http\Controllers\RealsUserCommentController;
use Utd\Reels\Http\Controllers\RealsUserLikesController;
use Utd\Reels\Http\Controllers\RealsUserViewsController;
use Utd\Reels\Http\Controllers\ReelGiftsController;
use Utd\Reels\Http\Controllers\ReportController;

/*
| Reels API routes.
| `package.enabled:reels` returns 403 while the package is disabled in
| admin/packages (replaces Eagle's appFeatureEnable:reel).
| NOTE(gap): other Eagle middleware not in the Base yet:
|   checkLatestToken, generalBan, userBan, ban.user.actions:reals,
|   update.last.seen — see NOTES_GAPS.md → "middleware".
*/
Route::middleware(['auth:sanctum', 'package.enabled:reels'])->group(function () {
    // Specific routes must precede the apiResource so they aren't swallowed by {real}.
    Route::get('reals/user/{user_id?}', [RealsController::class, 'getUserReals']);
    Route::get('reals/my-reals', [RealsController::class, 'getMyReals']);
    Route::get('reals/user-followers', [RealsController::class, 'getUserFollowersReals']);

    Route::apiResource('reals', RealsController::class)->only(['index', 'store', 'show', 'destroy']);
    Route::post('reals-update/{id}', [RealsController::class, 'update']);

    Route::get('reals/{real_id}/comment', [RealsUserCommentController::class, 'index']);
    Route::post('reals/{real_id}/comment', [RealsUserCommentController::class, 'store']);
    Route::post('reals/{real_id}/comment/{id}/like', [RealsUserCommentController::class, 'react']);
    Route::post('reals/{real_id}/comment/{id}/report', [RealsUserCommentController::class, 'report']);
    Route::delete('reals/{real_id}/comment/{id}', [RealsUserCommentController::class, 'destroy']);

    Route::get('reals/{real_id}/like', [RealsUserLikesController::class, 'index']);
    Route::post('reals/{real_id}/like', [RealsUserLikesController::class, 'store']);
    Route::delete('reals/{real_id}/like/{id}', [RealsUserLikesController::class, 'destroy']);

    Route::post('reals/{real_id}/view', [RealsUserViewsController::class, 'store']);
    Route::post('reals/{real_id}/report', [ReportController::class, 'store']);

    // Gifts — gracefully 503 until the Gifts package binds App\Contracts\GiftSender.
    Route::post('reals/{real_id}/gift', [ReelGiftsController::class, 'store']);
});
