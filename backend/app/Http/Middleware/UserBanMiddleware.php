<?php

namespace App\Http\Middleware;

use App\Helpers\Common;
use Closure;
use Illuminate\Http\Request;

class UserBanMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if (!$user || !$user->status) {
            return Common::apiResponse(false, 'Your account has been suspended', null, 403);
        }

        return $next($request);
    }
}
