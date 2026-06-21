<?php

namespace App\Http\Middleware;

use App\Support\AppLanguages;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;

class Localization
{
    public function handle(Request $request, Closure $next)
    {
        // Honour the app's chosen language (sent on every request as
        // X-localization) but only when it's an ACTIVE language in the DB, so a
        // newly added locale (fr, hi, …) works without code changes and a bogus
        // header can't set an arbitrary locale.
        $langCode = $request->header('X-localization', AppLanguages::defaultCode());

        if (AppLanguages::isActive($langCode)) {
            App::setLocale($langCode);
        }

        return $next($request);
    }
}
