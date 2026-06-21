<?php

namespace App\Http\Middleware;

use App\Models\Language;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Session;

class SetAdminLocale
{
    public function handle(Request $request, Closure $next): mixed
    {
        // 0. Explicit switch via ?lang= (used by the login-page language toggle,
        //    which runs BEFORE auth). Only accept active, known language codes so
        //    a crafted URL can't set an arbitrary locale.
        $requested = $request->query('lang');
        if (is_string($requested) && $requested !== '' && in_array($requested, $this->allowedLocales(), true)) {
            Session::put('admin_locale', $requested);
        }

        // 1. Admin's personal choice (stored in session)
        $locale = Session::get('admin_locale');

        // 2. Fallback to DB default language
        if (!$locale) {
            $locale = Language::where('is_default', true)->value('code')
                ?? config('app.locale', 'en');
            Session::put('admin_locale', $locale);
        }

        App::setLocale($locale);
        config(['app.locale' => $locale]);

        return $next($request);
    }

    /** Active language codes; falls back to en/ar when the table isn't seeded. */
    private function allowedLocales(): array
    {
        try {
            $codes = Language::where('is_active', true)->pluck('code')->all();
        } catch (\Throwable) {
            $codes = [];
        }

        return $codes !== [] ? $codes : ['en', 'ar'];
    }
}
