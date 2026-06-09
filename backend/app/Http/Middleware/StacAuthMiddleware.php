<?php

namespace App\Http\Middleware;

use App\Models\Config;
use Closure;
use Illuminate\Http\Request;

class StacAuthMiddleware
{
    public function handle(Request $request, Closure $next): mixed
    {
        $stacKey = Config::where('name', 'utd_stac_key')->value('value');

        if (! $stacKey || $request->header('X-Stac-Key') !== $stacKey) {
            return response()->json(['error' => 'Unauthorized — invalid Stac key'], 401);
        }

        return $next($request);
    }
}
