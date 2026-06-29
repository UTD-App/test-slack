<?php

namespace Tests\Feature\Coverage;

use App\Models\Config;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Endpoint coverage — authenticated user-facing surface that had no test:
 *   GET /users/search, GET /users/{id}, POST /users/online-status,
 *   POST /profile/avatar, GET/POST /settings, GET /configs.
 */
class UserEndpointsTest extends TestCase
{
    use RefreshDatabase;

    private function auth(User $user): static
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('test')->plainTextToken);
    }

    // ── users/search ───────────────────────────────────────────────────────
    public function test_search_finds_other_users_by_name(): void
    {
        $me    = User::factory()->create();
        $alice = User::factory()->create(['name' => 'Alice Wonder']);
        User::factory()->create(['name' => 'Zylo']);

        $this->auth($me)->getJson('/api/users/search?q=Alice')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonFragment(['id' => $alice->id, 'name' => 'Alice Wonder']);
    }

    public function test_search_excludes_self(): void
    {
        $me = User::factory()->create(['name' => 'Mirror']);

        $this->auth($me)->getJson('/api/users/search?q=Mirror')
            ->assertStatus(200)
            ->assertJsonPath('data', []);
    }

    public function test_search_empty_query_returns_empty(): void
    {
        $me = User::factory()->create();

        $this->auth($me)->getJson('/api/users/search?q=')
            ->assertStatus(200)
            ->assertJsonPath('data', []);
    }

    public function test_search_requires_auth(): void
    {
        $this->getJson('/api/users/search?q=x')->assertStatus(401);
    }

    // ── users/{id} ─────────────────────────────────────────────────────────
    public function test_show_user_returns_public_profile(): void
    {
        $me     = User::factory()->create();
        $target = User::factory()->create(['name' => 'Public Guy']);

        $this->auth($me)->getJson("/api/users/{$target->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.id', $target->id)
            ->assertJsonPath('data.is_me', false);
    }

    public function test_show_self_marks_is_me(): void
    {
        $me = User::factory()->create();

        $this->auth($me)->getJson("/api/users/{$me->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.is_me', true);
    }

    public function test_show_missing_user_is_404(): void
    {
        $me = User::factory()->create();

        $this->auth($me)->getJson('/api/users/999999')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    // ── online-status ──────────────────────────────────────────────────────
    public function test_online_status_returns_map_keyed_by_id(): void
    {
        $me    = User::factory()->create();
        $other = User::factory()->create();

        $this->auth($me)->postJson('/api/users/online-status', ['ids' => [$other->id]])
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['data' => [$other->id => ['is_online', 'last_seen']]]);
    }

    // ── profile/avatar ─────────────────────────────────────────────────────
    public function test_avatar_upload_stores_and_returns_url(): void
    {
        Storage::fake(config('filesystems.default'));
        $user = User::factory()->create();

        $this->auth($user)->postJson('/api/profile/avatar', [
            'image' => UploadedFile::fake()->image('me.jpg'),
        ])->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['data' => ['url', 'user']]);

        $this->assertDatabaseHas('profiles', ['user_id' => $user->id]);
    }

    public function test_avatar_upload_requires_image(): void
    {
        $user = User::factory()->create();

        // App's 422 convention (CValidationException) for a missing/invalid file.
        $this->auth($user)->postJson('/api/profile/avatar', [])
            ->assertStatus(422);
    }

    // ── settings ───────────────────────────────────────────────────────────
    public function test_get_settings_returns_envelope(): void
    {
        $user = User::factory()->create();

        $this->auth($user)->getJson('/api/settings')
            ->assertStatus(200)->assertJsonPath('status', true);
    }

    public function test_update_settings_persists_values(): void
    {
        $user = User::factory()->create();

        $this->auth($user)->postJson('/api/settings', [
            'settings' => ['privacy_show_online' => false],
        ])->assertStatus(200)->assertJsonPath('status', true);
    }

    public function test_update_settings_requires_settings_array(): void
    {
        $user = User::factory()->create();

        $this->auth($user)->postJson('/api/settings', [])
            ->assertStatus(422);
    }

    // ── configs ────────────────────────────────────────────────────────────
    public function test_configs_returns_only_visible_rows(): void
    {
        Config::create(['name' => 'visible_one', 'value' => 'yes', 'is_hidden' => false]);
        Config::create(['name' => 'secret_one', 'value' => 'no', 'is_hidden' => true]);

        $user = User::factory()->create();

        $this->auth($user)->getJson('/api/configs')
            ->assertStatus(200)
            ->assertJsonFragment(['name' => 'visible_one'])
            ->assertJsonMissing(['name' => 'secret_one']);
    }
}
