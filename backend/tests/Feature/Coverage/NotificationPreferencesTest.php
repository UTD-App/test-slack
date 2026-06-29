<?php

namespace Tests\Feature\Coverage;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Endpoint coverage — PUT /notifications/preferences (mute/unmute a category,
 * optionally per channel). The only notification route without a test.
 */
class NotificationPreferencesTest extends TestCase
{
    use RefreshDatabase;

    private function auth(User $user): static
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('test')->plainTextToken);
    }

    public function test_update_preference_upserts_row(): void
    {
        $user = User::factory()->create();

        $this->auth($user)->putJson('/api/notifications/preferences', [
            'category' => 'social',
            'channel'  => 'push',
            'enabled'  => false,
        ])->assertStatus(200)->assertJsonPath('status', true);

        $this->assertDatabaseHas('notification_preferences', [
            'user_id'  => $user->id,
            'category' => 'social',
            'channel'  => 'push',
            'enabled'  => false,
        ]);
    }

    public function test_update_preference_is_idempotent_upsert(): void
    {
        $user = User::factory()->create();

        $this->auth($user)->putJson('/api/notifications/preferences', [
            'category' => 'system', 'enabled' => false,
        ])->assertStatus(200);

        // Same (user, category, null channel) flips back to enabled — one row, not two.
        $this->auth($user)->putJson('/api/notifications/preferences', [
            'category' => 'system', 'enabled' => true,
        ])->assertStatus(200);

        $this->assertDatabaseCount('notification_preferences', 1);
    }

    public function test_update_preference_validates_input(): void
    {
        $user = User::factory()->create();

        $this->auth($user)->putJson('/api/notifications/preferences', ['category' => 'x'])
            ->assertStatus(422);
    }

    public function test_preferences_requires_auth(): void
    {
        $this->putJson('/api/notifications/preferences', [])->assertStatus(401);
    }
}
