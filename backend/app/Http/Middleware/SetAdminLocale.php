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
}
