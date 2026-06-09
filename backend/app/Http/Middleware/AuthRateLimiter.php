<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class AuthRateLimiter
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, string $maxAttempts = '5', string $decayMinutes = '1'): Response
    {
        // Create unique key based on IP + endpoint + identifier (email/phone if present)
        $key = $this->resolveRequestSignature($request);

        // Check if rate limit is exceeded
        if (RateLimiter::tooManyAttempts($key, $maxAttempts)) {
            $seconds = RateLimiter::availableIn($key);

            // Log suspicious activity
            Log::warning('Rate limit exceeded on auth endpoint', [
                'ip' => $request->ip(),
                'endpoint' => $request->path(),
                'user_agent' => $request->userAgent(),
                'identifier' => $this->getIdentifier($request),
                'available_in' => $seconds . ' seconds'
            ]);

            return response()->json([
                'message' => 'Too many attempts. Please try again in ' . ceil($seconds / 60) . ' minute(s).',
                'retry_after' => $seconds
            ], 429);
        }

        // Increment the counter
        RateLimiter::hit($key, $decayMinutes * 60);

        $response = $next($request);

        // If authentication failed (401 or 403), track it more strictly
        if (in_array($response->getStatusCode(), [401, 403, 422])) {
            $this->trackFailedAttempt($request);
        } else {
            // Clear failed attempts on success
            $this->clearFailedAttempts($request);
        }

        return $response;
    }

    /**
     * Resolve a unique request signature
     */
    protected function resolveRequestSignature(Request $request): string
    {
        $identifier = $this->getIdentifier($request);

        return 'auth_rate_limit:' .
               $request->path() . ':' .
               $request->ip() . ':' .
               $identifier;
    }

    /**
     * Get identifier from request (email, phone, username)
     */
    protected function getIdentifier(Request $request): string
    {
        return $request->input('email') ??
               $request->input('phone') ??
               $request->input('username') ??
               $request->input('identity') ??
               'anonymous';
    }

    /**
     * Track failed authentication attempts
     */
    protected function trackFailedAttempt(Request $request): void
    {
        $key = 'failed_auth:' . $request->ip();

        RateLimiter::hit($key, 3600); // Track for 1 hour

        $attempts = RateLimiter::attempts($key);

        // If too many failed attempts from this IP, log as potential attack
        if ($attempts > 10) {
            Log::alert('Multiple failed authentication attempts detected', [
                'ip' => $request->ip(),
                'attempts' => $attempts,
                'endpoint' => $request->path(),
                'user_agent' => $request->userAgent(),
                'identifier' => $this->getIdentifier($request),
                'last_hour' => true
            ]);
        }
    }

    /**
     * Clear failed attempts on successful auth
     */
    protected function clearFailedAttempts(Request $request): void
    {
        $key = 'failed_auth:' . $request->ip();
        RateLimiter::clear($key);
    }
}
