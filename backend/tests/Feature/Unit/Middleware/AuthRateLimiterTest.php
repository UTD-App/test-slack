<?php

namespace Tests\Feature\Unit\Middleware;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class AuthRateLimiterTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        RateLimiter::clear('auth_rate_limit:_t/rate:127.0.0.1:anonymous');
    }

    private function defineRoute(int $max = 3): void
    {
        // maxAttempts=3, decayMinutes=1
        Route::middleware(["auth.rate.limit:{$max},1"])
            ->post('/_t/rate', fn () => response()->json(['ok' => true]));
    }

    public function test_returns_429_after_max_attempts(): void
    {
        $this->defineRoute(3);

        // First 3 attempts are allowed (counter incremented each time).
        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/_t/rate')->assertStatus(200);
        }

        // 4th attempt exceeds the limit.
        $this->postJson('/_t/rate')
            ->assertStatus(429)
            ->assertJsonStructure(['message', 'retry_after']);
    }

    public function test_under_limit_passes(): void
    {
        $this->defineRoute(5);

        $this->postJson('/_t/rate')->assertStatus(200);
        $this->postJson('/_t/rate')->assertStatus(200);
    }
}
