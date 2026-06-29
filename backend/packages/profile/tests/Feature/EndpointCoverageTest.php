<?php

namespace Utd\Profile\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Endpoint coverage for the Profile package — the package had no tests.
 *
 * Surface: GET /api/users/{id}/profile (ProfileController@show) — the rich
 * server-driven profile (publicData + contributed sections + is_me), behind the
 * authenticated stack (auth:sanctum, checkLatestToken, generalBan, userBan,
 * update.last.seen).
 */
class EndpointCoverageTest extends TestCase
{
    use RefreshDatabase;

    private function auth(User $user): static
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('test')->plainTextToken);
    }

    public function test_profile_requires_auth(): void
    {
        $target = User::factory()->create();

        $this->getJson("/api/users/{$target->id}/profile")->assertStatus(401);
    }

    public function test_profile_returns_public_data_for_other_user(): void
    {
        $me     = User::factory()->create();
        $target = User::factory()->create(['name' => 'Profile Owner']);

        $this->auth($me)->getJson("/api/users/{$target->id}/profile")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.id', $target->id)
            ->assertJsonPath('data.is_me', false);
    }

    public function test_profile_marks_is_me_for_self(): void
    {
        $me = User::factory()->create();

        $this->auth($me)->getJson("/api/users/{$me->id}/profile")
            ->assertStatus(200)
            ->assertJsonPath('data.is_me', true);
    }

    public function test_profile_of_missing_user_is_404(): void
    {
        $me = User::factory()->create();

        $this->auth($me)->getJson('/api/users/99999/profile')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }
}
