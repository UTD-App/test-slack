<?php

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
