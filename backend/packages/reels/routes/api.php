<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Route;
use Utd\Reels\Database\Seeders\ReelsBulkSeeder;
use Utd\Reels\Entities\Real;
use Utd\Reels\Http\Controllers\RealsController;
use Utd\Reels\Http\Controllers\RealsUserCommentController;
use Utd\Reels\Http\Controllers\RealsUserLikesController;
use Utd\Reels\Http\Controllers\RealsUserViewsController;
use Utd\Reels\Http\Controllers\ReelGiftsController;
use Utd\Reels\Http\Controllers\ReportController;

/*
| Dev seed route — fills the feed with demo reels (ReelsBulkSeeder, ~100).
| GET /api/reals/seed runs freely in local/development/testing; in any other
| environment it requires ?key= to match config('reels.seed_key') (and is
| blocked when that key is unset). Registered BEFORE the resource group so it
| isn't swallowed by GET reals/{real}. Convenience only — not a product route.
*/
Route::get('reals/seed', function (Request $request) {
    $key = config('reels.seed_key');
    $allowed = app()->environment(['local', 'development', 'testing'])
        || ($key && hash_equals((string) $key, (string) $request->query('key', '')));

    abort_unless($allowed, 403, 'Reels seeding is disabled in this environment.');

    Artisan::call('db:seed', [
        '--class' => ReelsBulkSeeder::class,
        '--force' => true,
    ]);

    return response()->json([
        'status'  => true,
        'message' => 'Reels seeded.',
        'data'    => ['total_reels' => Real::count()],
    ]);
});

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
