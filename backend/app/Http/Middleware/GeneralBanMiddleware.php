<?php

namespace App\Http\Middleware;

use App\Helpers\Common;
use Closure;
use Illuminate\Http\Request;

class GeneralBanMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if (!$user || !$user->status) {
            // `code` lets the app distinguish a ban from other 403s (e.g. a
            // disabled package) and force the user to log out.
            return Common::apiResponse(false, 'Your account has been suspended', ['code' => 'account_suspended'], 403);
        }

        return $next($request);
    }
}
