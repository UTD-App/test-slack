<?php

use Illuminate\Support\Facades\Route;
use Utd\Moment\Http\Controllers\MomentController;
use Utd\Moment\Http\Controllers\MomentUserCommentController;
use Utd\Moment\Http\Controllers\MomentUserGiftsController;
use Utd\Moment\Http\Controllers\MomentUserLikesController;
use Utd\Moment\Http\Controllers\ReportController;

/*
| Moment API routes.
| `package.enabled:moment` returns 403 while the package is disabled in
| admin/packages (replaces Eagle's appFeatureEnable:moment).
| `generalBan` rejects suspended users (status=0) with a distinguishable 403
| (code=account_suspended) so the app logs them out.
| Mirrors the base authed stack so a banned / superseded-token user can't reach
| moment routes, and responses are localized + presence-tracked.
| NOTE(gap): still pending (need their own packages/flags): ban.user.actions:moment,
|   moment.allowed — see NOTES_GAPS.md → "middleware".
*/
Route::middleware(['auth:sanctum', 'checkLatestToken', 'generalBan', 'userBan', 'update.last.seen', 'localization', 'package.enabled:moment'])->group(function () {
    // A user's moments (profile package). Declared before the {moment} resource so "user" isn't captured as an id.
    Route::get('moment/user/{user_id}', [MomentController::class, 'userMoments'])->whereNumber('user_id');

    Route::apiResource('moment', MomentController::class)->only(['index', 'store', 'show', 'destroy']);

    Route::get('moment/{moment_id}/comment', [MomentUserCommentController::class, 'index']);
    Route::post('moment/{moment_id}/comment', [MomentUserCommentController::class, 'store']);
    Route::post('moment/{moment_id}/comment/{id}/like', [MomentUserCommentController::class, 'react']);
    Route::post('moment/{moment_id}/comment/{id}/report', [MomentUserCommentController::class, 'report']);
    Route::delete('moment/{moment_id}/comment/{id}', [MomentUserCommentController::class, 'destroy']);

    Route::get('moment/{moment_id}/like', [MomentUserLikesController::class, 'index']);
    Route::post('moment/{moment_id}/like', [MomentUserLikesController::class, 'store']);

    Route::post('moment/{moment_id}/report', [ReportController::class, 'store']);

    // Gifts — gracefully 503 until the Gifts package binds App\Contracts\GiftSender.
    Route::post('moment/{moment_id}/gift', [MomentUserGiftsController::class, 'store']);
    Route::get('moments/{id}/gifts', [MomentUserGiftsController::class, 'getGifts']);
    Route::get('moments/users/{id}/gifts', [MomentUserGiftsController::class, 'userGift']);
});
