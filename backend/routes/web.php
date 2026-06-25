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

// GET /run-gcs-test         → upload a tiny PNG, verify, then DELETE it
// GET /run-gcs-test?keep=1  → same but KEEP it so you can open the url and see it
Route::get('/run-gcs-test', function (\Illuminate\Http\Request $request) {
    app(\App\Services\StorageConfigService::class)->configure();
    $disk = config('filesystems.disks.' . config('filesystems.default'), []);

    $png = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
    $tmp = tempnam(sys_get_temp_dir(), 'gcs') . '.png';
    file_put_contents($tmp, $png);
    $file = new \Illuminate\Http\UploadedFile($tmp, 'gcs-test.png', 'image/png', null, true);

    $out = [
        'provider'        => config('filesystems.default'),
        'driver'          => $disk['driver'] ?? null,
        'bucket'          => $disk['bucket'] ?? null,
        'project_id'      => $disk['project_id'] ?? null,
        // Safe to expose on this temporary debug route: a path string + a bool,
        // never the key contents.
        'key_file_path'   => $disk['key_file_path'] ?? null,
        'key_file_exists' => isset($disk['key_file_path']) ? file_exists($disk['key_file_path']) : null,
    ];
    try {
        $r = \App\Facades\Media::upload($file, 'gcs-test');
        $out['url']            = $r->url;
        $out['exists_on_disk'] = \Illuminate\Support\Facades\Storage::exists($r->path);
        $http                  = \Illuminate\Support\Facades\Http::timeout(20)->get($r->url);
        $out['http']           = $http->status();
        $out['bytes']          = strlen($http->body());
        if ($request->boolean('keep')) {
            $out['kept'] = 'NOT deleted — open the url above to view the image';
        } else {
            \App\Facades\Media::delete($r->path);
        }
        $out['ok']             = ($out['exists_on_disk'] === true) && ($http->status() === 200);
    } catch (\Throwable $e) {
        $out['ok'] = false;
        // MediaUploadException masks the real driver error as a generic message
        // and keeps the cause as $previous — walk the whole chain so the actual
        // GCS error (403 read-only / uniform bucket-level access / missing key /
        // project mismatch) is visible here, not just "Failed to store...".
        $chain = [];
        for ($x = $e; $x !== null; $x = $x->getPrevious()) {
            $chain[] = get_class($x) . ': ' . $x->getMessage();
        }
        $out['error'] = $chain;
    } finally {
        @unlink($tmp);
    }

    // The disk isn't configured with throw=>true, so Storage::put() swallows the
    // real driver error and just returns false (hence the empty cause chain
    // above). Re-attempt the write on a clone of the disk WITH throw enabled so
    // the actual GCS error (403 / uniform-bucket-level-access / project / ACL)
    // is captured here.
    try {
        $probeDisk = $disk;
        $probeDisk['throw'] = true;
        config(['filesystems.disks._probe' => $probeDisk]);
        \Illuminate\Support\Facades\Storage::forgetDisk('_probe');
        \Illuminate\Support\Facades\Storage::disk('_probe')
            ->put('gcs-test/probe-' . substr(md5((string) $request->ip()), 0, 8) . '.png', $png, 'public');
        $out['probe'] = 'raw write succeeded';
        \Illuminate\Support\Facades\Storage::disk('_probe')->delete('gcs-test/probe.png');
    } catch (\Throwable $e) {
        $chain = [];
        for ($x = $e; $x !== null; $x = $x->getPrevious()) {
            $chain[] = get_class($x) . ': ' . $x->getMessage();
        }
        $out['probe_error'] = $chain;
    }

    return response()->json($out, 200, [], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
});
