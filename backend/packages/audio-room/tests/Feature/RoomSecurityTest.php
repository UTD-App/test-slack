<?php

namespace Utd\AudioRoom\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\AudioRoom\Entities\Room;

class RoomSecurityTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        return [$user, $token];
    }

    /** S3 — entering a room must NOT leak the Stream server_secret to the client. */
    public function test_enter_does_not_expose_server_secret(): void
    {
        config(['audio-room.utd_stream.server_secret' => 'TOP-SECRET']);

        [$owner, $token] = $this->actingUser();
        $room = Room::create([
            'num_id'    => 200001,
            'user_id'   => $owner->id,
            'room_name' => 'Sec Room',
        ]);

        $config = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/rooms/{$room->id}/enter")
            ->assertStatus(200)
            ->json('data.stream_config');

        $this->assertArrayHasKey('app_id', $config);
        $this->assertArrayNotHasKey('server_secret', $config);
        $this->assertStringNotContainsString('TOP-SECRET', json_encode($config));
    }

    /** S3 — the public room config endpoint must NOT expose the server_secret. */
    public function test_config_does_not_expose_server_secret(): void
    {
        config(['audio-room.utd_stream.server_secret' => 'TOP-SECRET']);
        [, $token] = $this->actingUser();

        $data = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/config/room')
            ->assertStatus(200)
            ->json('data');

        $this->assertArrayNotHasKey('server_secret', $data);
    }

    /** S8 — favoriting a room that doesn't exist is rejected (no dangling ids). */
    public function test_cannot_favorite_a_nonexistent_room(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/rooms/999999/favorite')
            ->assertStatus(404);
    }

    /** S4 — invalid input returns a clean 422 (not a 500) on api/* routes. */
    public function test_invalid_room_creation_returns_422_not_500(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/rooms', []) // missing required room_name + mode
            ->assertStatus(422)
            ->assertJsonPath('status', false);
    }
}
