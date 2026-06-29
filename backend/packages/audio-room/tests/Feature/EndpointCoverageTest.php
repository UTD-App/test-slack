<?php

namespace Utd\AudioRoom\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;
use Utd\AudioRoom\Entities\Room;
use Utd\AudioRoom\Entities\RoomAdministrator;
use Utd\AudioRoom\Entities\RoomBlacklist;
use Utd\AudioRoom\Entities\RoomCategory;
use Utd\AudioRoom\Entities\RoomVisitor;
use Utd\AudioRoom\Models\CharismaLevel;
use Utd\AudioRoom\Models\CharismaRoomData;

/**
 * Endpoint coverage for the audio-room package. One focused test per route that
 * is not already exercised by RoomMediaTest / RoomSecurityTest: correct auth,
 * expected HTTP status, response shape, and one meaningful side-effect.
 */
class EndpointCoverageTest extends TestCase
{
    use RefreshDatabase;

    /** @return array{0: User, 1: string} */
    private function actingUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        return [$user, $token];
    }

    private function headers(string $token): array
    {
        return ['Authorization' => "Bearer {$token}"];
    }

    private function makeRoom(User $owner, array $attrs = []): Room
    {
        static $seq = 0;
        $seq++;

        return Room::create(array_merge([
            'num_id'    => 300000 + $seq,
            'user_id'   => $owner->id,
            'room_name' => 'Cov Room ' . $seq,
        ], $attrs));
    }

    // ---------------------------------------------------------------------
    // Auth gate
    // ---------------------------------------------------------------------

    public function test_protected_route_requires_auth(): void
    {
        $this->getJson('/api/rooms')->assertStatus(401);
    }

    // ---------------------------------------------------------------------
    // Room listing / lookups
    // ---------------------------------------------------------------------

    public function test_index_lists_open_rooms(): void
    {
        [$owner, $token] = $this->actingUser();
        $this->makeRoom($owner);

        $res = $this->withHeaders($this->headers($token))
            ->getJson('/api/rooms')
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertCount(1, $res->json('data'));
    }

    public function test_mine_returns_own_room(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->getJson('/api/rooms/mine')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.id', $room->id);
    }

    public function test_mine_returns_null_when_no_room(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeaders($this->headers($token))
            ->getJson('/api/rooms/mine')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data', null);
    }

    public function test_favorites_returns_only_favorited_rooms(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        // Favorite it first, then list favorites.
        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/favorite")
            ->assertStatus(200)
            ->assertJsonPath('data.is_favorite', true);

        $res = $this->withHeaders($this->headers($token))
            ->getJson('/api/rooms/favorites')
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertCount(1, $res->json('data'));
        $this->assertSame($room->id, $res->json('data.0.id'));
    }

    public function test_categories_returns_top_level_only(): void
    {
        [, $token] = $this->actingUser();
        $parent = RoomCategory::create(['name' => 'Music', 'enable' => true, 'sort' => 1]);
        RoomCategory::create(['name' => 'Pop', 'parent_id' => $parent->id, 'enable' => true, 'sort' => 1]);

        $res = $this->withHeaders($this->headers($token))
            ->getJson('/api/rooms/categories')
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertCount(1, $res->json('data'));
        $this->assertSame($parent->id, $res->json('data.0.id'));
    }

    public function test_category_types_returns_children(): void
    {
        [, $token] = $this->actingUser();
        $parent = RoomCategory::create(['name' => 'Music', 'enable' => true, 'sort' => 1]);
        $child = RoomCategory::create(['name' => 'Pop', 'parent_id' => $parent->id, 'enable' => true, 'sort' => 1]);

        $res = $this->withHeaders($this->headers($token))
            ->getJson("/api/rooms/categories/{$parent->id}/types")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertCount(1, $res->json('data'));
        $this->assertSame($child->id, $res->json('data.0.id'));
    }

    // ---------------------------------------------------------------------
    // Room creation (success path; error path is in RoomSecurityTest)
    // ---------------------------------------------------------------------

    public function test_store_creates_a_room(): void
    {
        [$owner, $token] = $this->actingUser();

        $this->withHeaders($this->headers($token))
            ->postJson('/api/rooms', ['room_name' => 'New Room', 'mode' => 9])
            ->assertStatus(201)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.room_name', 'New Room');

        $this->assertDatabaseHas('rooms', ['user_id' => $owner->id, 'room_name' => 'New Room']);
    }

    public function test_store_rejects_second_room(): void
    {
        [$owner, $token] = $this->actingUser();
        $this->makeRoom($owner, ['type' => 'audio']);

        $this->withHeaders($this->headers($token))
            ->postJson('/api/rooms', ['room_name' => 'Another', 'mode' => 9])
            ->assertStatus(422)
            ->assertJsonPath('status', false);
    }

    // ---------------------------------------------------------------------
    // Update / delete + ownership
    // ---------------------------------------------------------------------

    public function test_owner_can_update_room(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->putJson("/api/rooms/{$room->id}", ['room_name' => 'Renamed'])
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.room_name', 'Renamed');

        $this->assertDatabaseHas('rooms', ['id' => $room->id, 'room_name' => 'Renamed']);
    }

    public function test_non_owner_cannot_update_room(): void
    {
        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        [, $otherToken] = $this->actingUser();

        $this->withHeaders($this->headers($otherToken))
            ->putJson("/api/rooms/{$room->id}", ['room_name' => 'Hacked'])
            ->assertStatus(403)
            ->assertJsonPath('status', false);
    }

    public function test_owner_can_delete_room(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->deleteJson("/api/rooms/{$room->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseMissing('rooms', ['id' => $room->id]);
    }

    public function test_non_owner_cannot_delete_room(): void
    {
        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        [, $otherToken] = $this->actingUser();

        $this->withHeaders($this->headers($otherToken))
            ->deleteJson("/api/rooms/{$room->id}")
            ->assertStatus(403);

        $this->assertDatabaseHas('rooms', ['id' => $room->id]);
    }

    // ---------------------------------------------------------------------
    // Room actions
    // ---------------------------------------------------------------------

    public function test_token_proxies_stream_engine(): void
    {
        Http::fake([
            '*/api/v1/token' => Http::response(['token' => 'signed-token'], 200),
        ]);

        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/token", [
                'identity' => (string) $owner->id,
                'service'  => 'livekit',
            ])
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.token', 'signed-token');
    }

    public function test_token_surfaces_engine_failure_without_secret(): void
    {
        config(['audio-room.utd_stream.server_secret' => 'TOP-SECRET']);
        Http::fake([
            '*/api/v1/token' => Http::response(['message' => 'denied'], 502),
        ]);

        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $res = $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/token", [
                'identity' => (string) $owner->id,
                'service'  => 'livekit',
            ])
            ->assertStatus(502)
            ->assertJsonPath('status', false);

        $this->assertStringNotContainsString('TOP-SECRET', json_encode($res->json()));
    }

    public function test_token_validates_required_fields(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/token", [])
            ->assertStatus(422)
            ->assertJsonPath('status', false);
    }

    public function test_exit_removes_visitor(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $owner->id]);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/exit")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseMissing('room_visitors', ['room_id' => $room->id, 'user_id' => $owner->id]);
    }

    public function test_toggle_favorite_adds_then_removes(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/favorite")
            ->assertStatus(200)
            ->assertJsonPath('data.is_favorite', true);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/favorite")
            ->assertStatus(200)
            ->assertJsonPath('data.is_favorite', false);
    }

    public function test_toggle_comments_requires_owner_or_admin(): void
    {
        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        [, $otherToken] = $this->actingUser();

        $this->withHeaders($this->headers($otherToken))
            ->postJson("/api/rooms/{$room->id}/comment-status", ['closed' => true])
            ->assertStatus(403);
    }

    public function test_owner_can_toggle_comments(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/comment-status", ['closed' => true])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('rooms', ['id' => $room->id, 'is_comment_closed' => true]);
    }

    public function test_change_mode_updates_room(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner, ['mode' => 9]);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/mode", ['mode' => 5])
            ->assertStatus(200)
            ->assertJsonPath('data.mode', 5);

        $this->assertDatabaseHas('rooms', ['id' => $room->id, 'mode' => 5]);
    }

    public function test_change_mode_rejects_non_owner(): void
    {
        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        [, $otherToken] = $this->actingUser();

        $this->withHeaders($this->headers($otherToken))
            ->postJson("/api/rooms/{$room->id}/mode", ['mode' => 5])
            ->assertStatus(403);
    }

    public function test_remove_password_clears_password(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner, ['room_pass' => 'secret']);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/remove-password")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('rooms', ['id' => $room->id, 'room_pass' => null]);
    }

    public function test_mute_writing_requires_owner_or_admin(): void
    {
        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $target = User::factory()->create();
        [, $otherToken] = $this->actingUser();

        $this->withHeaders($this->headers($otherToken))
            ->postJson("/api/rooms/{$room->id}/mute-writing", ['user_id' => $target->id])
            ->assertStatus(403);
    }

    public function test_owner_can_mute_writing(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $target = User::factory()->create();

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/mute-writing", ['user_id' => $target->id])
            ->assertStatus(200)
            ->assertJsonPath('status', true);
    }

    public function test_owner_can_unmute_writing(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $target = User::factory()->create();

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/unmute-writing", ['user_id' => $target->id])
            ->assertStatus(200)
            ->assertJsonPath('status', true);
    }

    public function test_send_banner_requires_owner_or_admin(): void
    {
        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        [, $otherToken] = $this->actingUser();

        $this->withHeaders($this->headers($otherToken))
            ->postJson("/api/rooms/{$room->id}/yellow-banner", ['message' => 'hi'])
            ->assertStatus(403);
    }

    public function test_owner_can_send_banner(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/yellow-banner", ['message' => 'Welcome'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);
    }

    public function test_pin_message_persists_pinned_message(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/pin-message", [
                'text'        => 'Read the rules',
                'sender_id'   => $owner->id,
                'sender_name' => 'Owner',
                'timestamp'   => 1234567890,
            ])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $room->refresh();
        $this->assertSame('Read the rules', $room->pinned_message['text']);
    }

    public function test_unpin_message_clears_pinned_message(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner, [
            'pinned_message' => ['senderId' => '1', 'senderName' => 'X', 'text' => 'Y', 'senderAvatar' => '', 'timestamp' => 1],
        ]);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/unpin-message")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $room->refresh();
        $this->assertNull($room->pinned_message);
    }

    public function test_users_lists_room_visitors(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $visitor = User::factory()->create();
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $visitor->id]);

        $res = $this->withHeaders($this->headers($token))
            ->getJson("/api/rooms/{$room->id}/users")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertCount(1, $res->json('data'));
        $this->assertSame($visitor->id, $res->json('data.0.id'));
    }

    public function test_ranking_returns_empty_list(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->getJson("/api/rooms/{$room->id}/ranking")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data', []);
    }

    // ---------------------------------------------------------------------
    // Webhook (public, secret-gated)
    // ---------------------------------------------------------------------

    public function test_webhook_rejects_bad_secret(): void
    {
        config(['audio-room.utd_stream.server_secret' => 'WEBHOOK-SECRET']);

        $this->postJson('/api/webhook/stream', ['event' => 'participant_left'], [
            'X-Stream-Secret' => 'wrong',
        ])->assertStatus(401);
    }

    public function test_webhook_removes_visitor_on_participant_left(): void
    {
        config(['audio-room.utd_stream.server_secret' => 'WEBHOOK-SECRET']);

        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $visitor = User::factory()->create();
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $visitor->id]);

        $this->postJson('/api/webhook/stream', [
            'event'       => 'participant_left',
            'room'        => ['name' => (string) $room->id],
            'participant' => ['identity' => (string) $visitor->id],
        ], ['X-Stream-Secret' => 'WEBHOOK-SECRET'])
            ->assertStatus(200)
            ->assertJsonPath('ok', true);

        $this->assertDatabaseMissing('room_visitors', ['room_id' => $room->id, 'user_id' => $visitor->id]);
    }

    // ---------------------------------------------------------------------
    // Admin & blacklist
    // ---------------------------------------------------------------------

    public function test_admins_index_lists_admins(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $admin = User::factory()->create();
        RoomAdministrator::create([
            'room_id' => $room->id, 'user_id' => $admin->id,
            'assigned_by' => $owner->id, 'assigned_at' => now(),
        ]);

        $res = $this->withHeaders($this->headers($token))
            ->getJson("/api/rooms/{$room->id}/admins")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertCount(1, $res->json('data'));
        $this->assertSame($admin->id, $res->json('data.0.id'));
    }

    public function test_owner_can_add_admin_who_is_visitor(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $candidate = User::factory()->create();
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $candidate->id]);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/admins", ['user_id' => $candidate->id])
            ->assertStatus(201)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('room_administrators', [
            'room_id' => $room->id, 'user_id' => $candidate->id,
        ]);
    }

    public function test_add_admin_rejects_non_visitor(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $candidate = User::factory()->create(); // not a visitor

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/admins", ['user_id' => $candidate->id])
            ->assertStatus(422)
            ->assertJsonPath('status', false);
    }

    public function test_non_owner_cannot_add_admin(): void
    {
        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $candidate = User::factory()->create();
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $candidate->id]);
        [, $otherToken] = $this->actingUser();

        $this->withHeaders($this->headers($otherToken))
            ->postJson("/api/rooms/{$room->id}/admins", ['user_id' => $candidate->id])
            ->assertStatus(403);
    }

    public function test_owner_can_remove_admin(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $admin = User::factory()->create();
        RoomAdministrator::create([
            'room_id' => $room->id, 'user_id' => $admin->id,
            'assigned_by' => $owner->id, 'assigned_at' => now(),
        ]);

        $this->withHeaders($this->headers($token))
            ->deleteJson("/api/rooms/{$room->id}/admins/{$admin->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseMissing('room_administrators', [
            'room_id' => $room->id, 'user_id' => $admin->id,
        ]);
    }

    public function test_blacklist_lists_active_bans(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $banned = User::factory()->create();
        RoomBlacklist::create([
            'room_id' => $room->id, 'user_id' => $banned->id,
            'banned_by' => $owner->id, 'banned_at' => now(),
            'is_active' => true, 'reason' => 'spam',
        ]);

        $res = $this->withHeaders($this->headers($token))
            ->getJson("/api/rooms/{$room->id}/blacklist")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertCount(1, $res->json('data'));
        $this->assertSame($banned->id, $res->json('data.0.id'));
    }

    public function test_owner_can_kick_user(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $target = User::factory()->create();
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $target->id]);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/kick", ['user_id' => $target->id, 'minutes' => 5])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        // Kick = temp ban + removed from visitors.
        $this->assertDatabaseHas('room_blacklist', ['room_id' => $room->id, 'user_id' => $target->id]);
        $this->assertDatabaseMissing('room_visitors', ['room_id' => $room->id, 'user_id' => $target->id]);
    }

    public function test_kick_cannot_target_owner(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/kick", ['user_id' => $owner->id])
            ->assertStatus(422)
            ->assertJsonPath('status', false);
    }

    public function test_owner_can_ban_user(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $target = User::factory()->create();
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $target->id]);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/ban", [
                'user_id' => $target->id, 'reason' => 'abuse',
            ])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('room_blacklist', [
            'room_id' => $room->id, 'user_id' => $target->id, 'is_active' => true,
        ]);
        $this->assertDatabaseMissing('room_visitors', ['room_id' => $room->id, 'user_id' => $target->id]);
    }

    public function test_non_admin_cannot_ban(): void
    {
        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $target = User::factory()->create();
        [, $otherToken] = $this->actingUser();

        $this->withHeaders($this->headers($otherToken))
            ->postJson("/api/rooms/{$room->id}/ban", ['user_id' => $target->id])
            ->assertStatus(403);
    }

    public function test_owner_can_unban_user(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $target = User::factory()->create();
        RoomBlacklist::create([
            'room_id' => $room->id, 'user_id' => $target->id,
            'banned_by' => $owner->id, 'banned_at' => now(), 'is_active' => true,
        ]);

        $this->withHeaders($this->headers($token))
            ->deleteJson("/api/rooms/{$room->id}/blacklist/{$target->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('room_blacklist', [
            'room_id' => $room->id, 'user_id' => $target->id, 'is_active' => false,
        ]);
    }

    public function test_check_role_reports_owner(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);

        $this->withHeaders($this->headers($token))
            ->postJson("/api/rooms/{$room->id}/check-role")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.is_owner', true)
            ->assertJsonPath('data.is_admin', false)
            ->assertJsonPath('data.is_banned', false);
    }

    // ---------------------------------------------------------------------
    // Charisma
    // ---------------------------------------------------------------------

    public function test_charisma_levels_returns_levels(): void
    {
        [, $token] = $this->actingUser();
        CharismaLevel::create(['level' => 1, 'points' => 100, 'image' => 'lvl1.png']);

        $res = $this->withHeaders($this->headers($token))
            ->getJson('/api/charisma/levels')
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertCount(1, $res->json('data'));
    }

    public function test_room_charisma_returns_ranked_entries(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $a = User::factory()->create();
        $b = User::factory()->create();
        CharismaRoomData::create(['room_id' => $room->id, 'user_id' => $a->id, 'total' => 50]);
        CharismaRoomData::create(['room_id' => $room->id, 'user_id' => $b->id, 'total' => 90]);

        $res = $this->withHeaders($this->headers($token))
            ->getJson("/api/charisma/room/{$room->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        // Highest total first, with position index.
        $this->assertSame($b->id, $res->json('data.0.user_id'));
        $this->assertSame(0, $res->json('data.0.position'));
    }

    public function test_charisma_status_returns_room_flag(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        // charizma_status is not in $fillable; set + persist it directly.
        $room->charizma_status = true;
        $room->save();

        $this->withHeaders($this->headers($token))
            ->getJson("/api/charisma/status/{$room->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.charisma_status', true);
    }

    public function test_charisma_status_404_for_missing_room(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeaders($this->headers($token))
            ->getJson('/api/charisma/status/999999')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    public function test_owner_can_change_charisma_status(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner, ['charizma_status' => false]);

        $this->withHeaders($this->headers($token))
            ->postJson('/api/charisma/change-status', ['room_id' => $room->id, 'status' => true])
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.charisma_status', true);

        $this->assertDatabaseHas('rooms', ['id' => $room->id, 'charizma_status' => true]);
    }

    public function test_non_owner_cannot_change_charisma_status(): void
    {
        [$owner] = $this->actingUser();
        $room = $this->makeRoom($owner);
        [, $otherToken] = $this->actingUser();

        $this->withHeaders($this->headers($otherToken))
            ->postJson('/api/charisma/change-status', ['room_id' => $room->id, 'status' => true])
            ->assertStatus(403);
    }

    public function test_owner_can_reset_charisma(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = $this->makeRoom($owner);
        $u = User::factory()->create();
        CharismaRoomData::create(['room_id' => $room->id, 'user_id' => $u->id, 'total' => 75]);

        $this->withHeaders($this->headers($token))
            ->postJson('/api/charisma/reset', ['room_id' => $room->id])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('charisma_room_data', [
            'room_id' => $room->id, 'user_id' => $u->id, 'total' => 0,
        ]);
    }
}
