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

/*
| Post-deploy bootstrap — run migrations + seeders + package sync from a browser
| so you don't need shell access. Guarded by the SETUP_KEY env secret; if it's
| empty or the key in the URL doesn't match, the route returns 404 (stays hidden).
|
|   GET /setup/<SETUP_KEY>                     → migrate + db:seed + utd:sync-packages
|   GET /setup/<SETUP_KEY>?email=you@x.com     → also promote that admin to super_admin
|
| Seeders are idempotent (safe to re-run). Clear SETUP_KEY afterwards to disable.
*/
Route::get('/setup/{key}', function (string $key, \Illuminate\Http\Request $request) {
    $expected = (string) config('app.setup_key');
    abort_unless($expected !== '' && hash_equals($expected, $key), 404);

    @set_time_limit(300);

    $steps = [];
    Artisan::call('migrate', ['--force' => true]);
    $steps['migrate'] = trim(Artisan::output());
    Artisan::call('db:seed', ['--force' => true]);
    $steps['seed'] = trim(Artisan::output());
    Artisan::call('utd:sync-packages');
    $steps['sync'] = trim(Artisan::output());

    // Optional: make a specific account a super_admin (gets ALL permissions).
    $promoted = null;
    if ($email = $request->query('email')) {
        $user = \App\Models\AdminUser::where('email', $email)->first();
        if ($user) {
            $role = \App\Models\AdminRole::firstOrCreate(['name' => 'super_admin'], ['label' => 'Super Admin']);
            $user->roles()->syncWithoutDetaching([$role->id]);
            $promoted = "{$email} is now super_admin";
        } else {
            $promoted = "no admin found with email: {$email}";
        }
    }

    return response()->json([
        'ok'       => true,
        'steps'    => $steps,
        'promoted' => $promoted,
        'note'     => 'Done. Clear SETUP_KEY in .env to disable this route.',
    ], 200, [], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
})->name('setup');

/*
| GCS upload smoke test — uploads a tiny PNG through the real Media pipeline,
| checks it landed on the configured disk, fetches its public URL, then deletes
| it. Use it to confirm Google Cloud Storage is wired correctly from a browser.
| Guarded by the same SETUP_KEY secret (wrong/empty key → 404).
|
|   GET /setup/gcs-test/<SETUP_KEY>
*/
Route::get('/setup/gcs-test/{key}', function (string $key) {
    $expected = (string) config('app.setup_key');
    abort_unless($expected !== '' && hash_equals($expected, $key), 404);

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
        $out['path']            = $r->path;
        $out['url']             = $r->url;
        $out['exists_on_disk']  = \Illuminate\Support\Facades\Storage::exists($r->path);
        $http                   = \Illuminate\Support\Facades\Http::timeout(20)->get($r->url);
        $out['public_url_http'] = $http->status();
        $out['bytes']           = strlen($http->body());
        \App\Facades\Media::delete($r->path);
        $out['cleanup']         = 'deleted';
        $out['ok']              = ($out['exists_on_disk'] === true) && ($http->status() === 200);
    } catch (\Throwable $e) {
        $out['ok']    = false;
        $out['error'] = $e->getMessage();
    } finally {
        @unlink($tmp);
    }

    return response()->json($out, 200, [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
})->name('setup.gcs-test');
