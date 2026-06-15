<?php

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Session;

Route::get('/', function () {
    $appName  = \App\Models\Config::where('name', 'app_name')->value('value') ?? config('app.name');
    $settings = \App\Models\Config::whereIn('name', [
        'app_primary_color', 'app_secondary_color', 'app_logo',
    ])->pluck('value', 'name');

    return view('welcome', compact('appName', 'settings'));
});

// Admin locale switcher
Route::get('/admin/locale/{locale}', function (string $locale) {
    Session::put('admin_locale', $locale);
    $previous = url()->previous();
    return redirect($previous ?: '/admin');
})->name('admin.locale');

/* ===== TEMPORARY — unguarded. REMOVE after use (no auth on purpose). ===== */

// GET /run-setup            → migrate + db:seed + utd:sync-packages
// GET /run-setup?email=x@y  → also make that admin a super_admin
Route::get('/run-setup', function (\Illuminate\Http\Request $request) {
    @set_time_limit(300);
    $out = [];
    Artisan::call('migrate', ['--force' => true]);
    $out['migrate'] = trim(Artisan::output());
    Artisan::call('db:seed', ['--force' => true]);
    $out['seed'] = trim(Artisan::output());
    Artisan::call('utd:sync-packages');
    $out['sync'] = trim(Artisan::output());

    if ($email = $request->query('email')) {
        $user = \App\Models\AdminUser::where('email', $email)->first();
        if ($user) {
            $role = \App\Models\AdminRole::firstOrCreate(['name' => 'super_admin'], ['label' => 'Super Admin']);
            $user->roles()->syncWithoutDetaching([$role->id]);
            $out['promoted'] = "{$email} is now super_admin";
        } else {
            $out['promoted'] = "no admin found with email: {$email}";
        }
    }

    return response()->json($out, 200, [], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
});

// GET /run-gcs-test → upload a tiny PNG to the configured disk, verify + delete
Route::get('/run-gcs-test', function () {
    app(\App\Services\StorageConfigService::class)->configure();
    $disk = config('filesystems.disks.' . config('filesystems.default'), []);

    $png = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
    $tmp = tempnam(sys_get_temp_dir(), 'gcs') . '.png';
    file_put_contents($tmp, $png);
    $file = new \Illuminate\Http\UploadedFile($tmp, 'gcs-test.png', 'image/png', null, true);

    $out = [
        'provider' => config('filesystems.default'),
        'driver'   => $disk['driver'] ?? null,
        'bucket'   => $disk['bucket'] ?? null,
    ];
    try {
        $r = \App\Facades\Media::upload($file, 'gcs-test');
        $out['url']            = $r->url;
        $out['exists_on_disk'] = \Illuminate\Support\Facades\Storage::exists($r->path);
        $http                  = \Illuminate\Support\Facades\Http::timeout(20)->get($r->url);
        $out['http']           = $http->status();
        $out['bytes']          = strlen($http->body());
        \App\Facades\Media::delete($r->path);
        $out['ok']             = ($out['exists_on_disk'] === true) && ($http->status() === 200);
    } catch (\Throwable $e) {
        $out['ok']    = false;
        $out['error'] = $e->getMessage();
    } finally {
        @unlink($tmp);
    }

    return response()->json($out, 200, [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
});
