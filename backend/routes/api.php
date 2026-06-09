<?php

use App\Http\Controllers\Api\V1\Auth\ForgotPasswordController;
use App\Http\Controllers\Api\V1\Auth\RegisterController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ConfigController;
use App\Http\Controllers\Api\V1\PackageController;
use App\Http\Controllers\Api\V1\StacController;
use App\Http\Controllers\Api\V1\MenuController;
use App\Http\Controllers\Api\V1\TranslationController;
use App\Http\Controllers\Api\V1\UtdManifestController;
use Illuminate\Support\Facades\Route;

// HAProxy health check — must be outside throttle middleware
Route::get('/health', function () {
    return response('ok', 200);
})->withoutMiddleware(['throttle:api', 'throttle']);

Route::post('/check-email', [AuthController::class, 'checkEmail']);

// Package registration & discovery
Route::get('/packages/installed', [PackageController::class, 'installed']);
Route::post('/packages/register', [PackageController::class, 'register']);

// ── UTD Studio — design-time discovery (manifest) ────────────────
// Separate auth from push: X-UTD-Secret (read) vs X-Stac-Key (write).
// Contract: utdStack/docs/INTEGRATION.md §2–3.
Route::middleware('utd.secret')->prefix('utd')->group(function () {
    Route::get('/manifest', [UtdManifestController::class, 'manifest']);
    Route::get('/packages/{key}/sample', [UtdManifestController::class, 'sample']);
});

// Stac server-driven UI
Route::post('/stac/push', [StacController::class, 'push']);

// UTD Studio: GET /stac/packages — returns installed packages with their screens
// UTD Studio appends /api/stac/packages to the server URL
Route::get('/stac/packages', function (\Illuminate\Http\Request $request) {
    // Auth: if a Stac Key is configured, verify it. If no key configured, allow (dev mode).
    $configuredKey = \App\Models\Config::where('name', 'utd_stac_key')->value('value');
    $sentKey       = $request->header('X-Stac-Key');

    if ($configuredKey && $sentKey !== $configuredKey) {
        return response()->json(['message' => 'Unauthorized — invalid X-Stac-Key'], 401);
    }

    // Base package screens (always available)
    $packages = [[
        'name'    => 'Base Project',
        'slug'    => 'base',
        'version' => '1.0.0',
        'screens' => [
            ['name' => 'login',    'label' => 'Login Screen'],
            ['name' => 'register', 'label' => 'Register Screen'],
            ['name' => 'home',     'label' => 'Home Screen'],
            ['name' => 'profile',  'label' => 'Profile Screen'],
            ['name' => 'settings', 'label' => 'Settings Screen'],
        ],
    ]];

    // Installed packages (from registered translation keys grouped by package)
    // Excluded: all base project lang files that are NOT packages
    $baseGroups = ['app', 'admin', 'auth', 'dashboard', 'messages', 'api', 'validation', 'pagination', 'passwords', 'countries'];
    $installedSlugs = \App\Models\TranslationKey::distinct()
        ->whereNotIn('group', $baseGroups)
        ->pluck('group');

    foreach ($installedSlugs as $slug) {
        $packages[] = [
            'name'    => ucwords(str_replace(['-', '_'], ' ', $slug)),
            'slug'    => $slug,
            'version' => '1.0.0',
            'screens' => [],
        ];
    }

    return response()->json($packages);
});

// UTD Studio calls this to discover available screens from installed packages
Route::get('/stac/screens', function () {
    // Returns screens registered by packages via POST /api/packages/register
    // Each package pushes its screen manifest when installed
    $screens = \App\Models\StacScreen::where('is_active', true)
        ->select('name', 'package', 'version')
        ->get();

    return \App\Helpers\Common::apiResponse(true, '', $screens);
})->middleware('stac.auth');

Route::get('/stac', [StacController::class, 'index']);
Route::get('/stac/{name}/version', [StacController::class, 'version']);
Route::get('/stac/{name}', [StacController::class, 'show']);

// Public translation endpoints
Route::get('/translations/supported', [TranslationController::class, 'supported']);
Route::get('/translations/{locale}/version', [TranslationController::class, 'version']);
Route::get('/translations/{locale}', [TranslationController::class, 'index']);

// App menu (server-driven; enabled packages only). Mirrors translations/stac pattern.
Route::get('/menu/version', [MenuController::class, 'version']);
Route::get('/menu', [MenuController::class, 'index']);

Route::prefix(config('app.api_prefix'))->group(function () {

    // ── Auth (public) ────────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::get('all-countries', [RegisterController::class, 'countries']);
        Route::post('register', [AuthController::class, 'register'])->middleware('auth.rate.limit:5,1');
        Route::post('login', [AuthController::class, 'login'])->middleware('auth.rate.limit:5,1');
        Route::post('forgot-password', [ForgotPasswordController::class, 'sendResetToken'])->middleware('auth.rate.limit:3,5');
        Route::post('reset-password', [ForgotPasswordController::class, 'reset'])->middleware('auth.rate.limit:3,5');
    });

    // ── Authenticated routes ─────────────────────────────────
    Route::middleware(['auth:sanctum', 'checkLatestToken', 'generalBan', 'userBan', 'update.last.seen', 'localization'])->group(
        function () {
            Route::get('my-data', [AuthController::class, 'myData']);
            Route::post('profile/update', [AuthController::class, 'updateProfile']);
            Route::post('profile/avatar', [AuthController::class, 'updateAvatar']);
            Route::post('auth/logout', [AuthController::class, 'logout']);

            // User settings
            Route::get('settings', [AuthController::class, 'getSettings']);
            Route::post('settings', [AuthController::class, 'updateSettings']);

            // User roles
            Route::get('roles', [AuthController::class, 'getRoles']);

            // App configs
            Route::get('configs', [ConfigController::class, 'index']);
        }
    );
});
