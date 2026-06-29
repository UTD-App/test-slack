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
| environment (e.g. prod) it requires ?key= to match the seed key. The key
| comes from config('reels.seed_key') (override via REELS_SEED_KEY) and falls
| back to a baked-in default so it works on a config-cached server WITHOUT an
| env change: /api/reals/seed?key=utd-reels-seed. Registered BEFORE the resource
| group so it isn't swallowed by GET reals/{real}. Convenience only.
*/
Route::get('reals/seed', function (Request $request) {
    $key = config('reels.seed_key') ?: 'utd-reels-seed';
    $allowed = app()->environment(['local', 'development', 'testing'])
        || hash_equals((string) $key, (string) $request->query('key', ''));

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
| `throttle:300,1` = a per-user abuse ceiling (300 req/min ≈ 5/s) — far above
| normal scroll/view/interaction traffic, but blocks scripted floods (mass
| like/comment/view). Tune via the number if a power-user ever hits 429.
| Mirrors the base authed stack so a banned / superseded-token user can't reach
| reels routes, and responses are localized + presence-tracked.
| NOTE(gap): still pending (need their own package): ban.user.actions:reals —
|   see NOTES_GAPS.md → "middleware".
*/
Route::middleware(['auth:sanctum', 'checkLatestToken', 'generalBan', 'userBan', 'update.last.seen', 'localization', 'package.enabled:reels', 'throttle:300,1'])->group(function () {
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
