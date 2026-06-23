<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * A6 — completing the profile must clear the first-run flag.
 *
 * `is_first` (read from the `is_points_first` column by register / login /
 * my-data) is set true at registration and was never reset, so a returning user
 * was sent through the complete-profile flow forever. updateProfile now clears
 * it once the user fills in their profile.
 */
class ProfileCompletionTest extends TestCase
{
    use RefreshDatabase;

    public function test_completing_profile_clears_is_first_flag(): void
    {
        $user = User::factory()->create(['is_points_first' => true]);
        $token = $user->createToken('test')->plainTextToken;

        // my-data still reports first-run before completion.
        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/my-data')
            ->assertStatus(200)
            ->assertJsonPath('data.is_first', true);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/profile/update', ['name' => 'QA Tester', 'gender' => 1])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        // Column is cleared in the DB …
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'is_points_first' => false,
        ]);

        // … and my-data now reports the user is no longer first-run.
        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/my-data')
            ->assertStatus(200)
            ->assertJsonPath('data.is_first', false);
    }
}
