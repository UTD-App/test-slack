<?php

namespace Tests\Feature\Unit\Middleware;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class CheckLatestTokenTest extends TestCase
{
    use RefreshDatabase;

    private function defineRoute(): void
    {
        Route::middleware(['auth:sanctum', 'checkLatestToken'])
            ->get('/_t/latest-token', fn () => response()->json(['ok' => true]));
    }

    public function test_latest_token_passes(): void
    {
        $this->defineRoute();

        $user  = User::factory()->create();
        $token = $user->createToken('t')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/_t/latest-token')
            ->assertStatus(200)
            ->assertJsonPath('ok', true);
    }

    public function test_older_token_is_rejected_when_newer_one_exists(): void
    {
        $this->defineRoute();

        $user      = User::factory()->create();
        $oldToken  = $user->createToken('old')->plainTextToken;
        // A second (newer) token now exists, so the old one is no longer "latest".
        $user->createToken('new')->plainTextToken;

        // A superseded token now returns 401 (was 505 — a wrong status that breaks
        // proxies/clients), with a localized message.
        $this->withHeader('Authorization', "Bearer {$oldToken}")
            ->getJson('/_t/latest-token')
            ->assertStatus(401)
            ->assertJsonPath('status', false)
            ->assertJsonPath('message', __('messages.another_device_login'));
    }
}
