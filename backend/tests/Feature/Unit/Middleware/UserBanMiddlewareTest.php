<?php

namespace Tests\Feature\Unit\Middleware;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class UserBanMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    private function defineRoute(): void
    {
        Route::middleware(['auth:sanctum', 'userBan'])
            ->get('/_t/user-ban', fn () => response()->json(['ok' => true]));
    }

    public function test_active_user_passes(): void
    {
        $this->defineRoute();

        $user  = User::factory()->create(['status' => true]);
        $token = $user->createToken('t')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/_t/user-ban')
            ->assertStatus(200)
            ->assertJsonPath('ok', true);
    }

    public function test_suspended_user_gets_403(): void
    {
        $this->defineRoute();

        $user  = User::factory()->inactive()->create();
        $token = $user->createToken('t')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/_t/user-ban')
            ->assertStatus(403)
            ->assertJsonPath('status', false);
    }
}
