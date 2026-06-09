<?php

namespace App\Http\Middleware;

use App\Helpers\Common;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Laravel\Sanctum\PersonalAccessToken;
use Laravel\Sanctum\Sanctum;
use Symfony\Component\HttpFoundation\Response;

class CheckLatestToken
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Check if the user is authenticated
        if (Auth::check()) {
            $user = Auth::user();
            $bearerToken = $request->bearerToken();
            $latestToken = $user->tokens()->orderByDesc('id')->first();

            if (!$latestToken) {
                return Common::apiResponse(false, 'Unauthenticated', [], 401);
            }
            $lastToken = $latestToken->token;

            if (strpos($bearerToken, '|') !== false) {
                [$id, $bearerToken] = explode('|', $bearerToken, 2);
            }
            $token = hash('sha256', $bearerToken);

            if (!hash_equals($lastToken, $token)) {
                return Common::apiResponse(0, 'Another device login with your account', null, 505);
            }
        }

        return $next($request);
    }
}
