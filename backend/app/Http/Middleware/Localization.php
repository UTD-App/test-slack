<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;

class Localization
{
    public function handle(Request $request, Closure $next)
    {
        $langCode = $request->header('X-localization', 'en');

        $supported = config('app.supported_locales', ['en', 'ar']);

        if (in_array($langCode, $supported)) {
            App::setLocale($langCode);
        }

        return $next($request);
    }
}
