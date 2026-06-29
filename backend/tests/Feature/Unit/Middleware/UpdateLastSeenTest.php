<?php

namespace Tests\Feature\Unit\Middleware;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class UpdateLastSeenTest extends TestCase
{
    use RefreshDatabase;

    private function defineRoute(): void
    {
        Route::middleware(['auth:sanctum', 'update.last.seen'])
            ->get('/_t/last-seen', fn () => response()->json(['ok' => true]));
    }

    public function test_bumps_online_time_on_first_request(): void
    {
        $this->defineRoute();

        $user  = User::factory()->create(['online_time' => null]);
        $token = $user->createToken('t')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/_t/last-seen')
            ->assertStatus(200);

        $user->refresh();
        $this->assertNotNull($user->online_time);
        $this->assertTrue(Cache::has('user_last_seen_' . $user->id));
    }

    public function test_does_not_rebump_within_cache_window(): void
    {
        $this->defineRoute();

        $user  = User::factory()->create(['online_time' => null]);
        $token = $user->createToken('t')->plainTextToken;

        // Prime the throttle cache so the middleware should skip the update.
        Cache::put('user_last_seen_' . $user->id, true, now()->addMinutes(5));

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/_t/last-seen')
            ->assertStatus(200);

        $user->refresh();
        $this->assertNull($user->online_time);
    }
}
