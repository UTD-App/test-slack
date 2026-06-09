<?php

namespace App\Http\Middleware;

use App\Models\Config;
use Closure;
use Illuminate\Http\Request;

/**
 * Guards the design-time UTD Studio endpoints (manifest / sample).
 *
 * Uses the `utd_secret` config value — a DIFFERENT key from `utd_stac_key`
 * (which guards the deploy-time /api/stac/push). The Studio sends it as
 * the `X-UTD-Secret` header.
 *
 * Dev mode: if no secret is configured yet, requests are allowed so the
 * integration can be exercised locally before the client pastes the secret.
 */
class VerifyUtdSecret
{
    public function handle(Request $request, Closure $next): mixed
    {
        $secret = Config::where('name', 'utd_secret')->value('value');

        if ($secret && $request->header('X-UTD-Secret') !== $secret) {
            return response()->json([
                'error'   => 'unauthorized',
                'message' => 'Invalid secret',
            ], 401);
        }

        return $next($request);
    }
}
