<?php

namespace Utd\AudioRoom\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use Utd\AudioRoom\Contracts\AudioRoomDataContributor;
use Utd\AudioRoom\Entities\Room;
use Utd\AudioRoom\Entities\RoomAdministrator;
use Utd\AudioRoom\Entities\RoomBlacklist;
use Utd\AudioRoom\Entities\RoomCategory;
use Utd\AudioRoom\Entities\RoomVisitor;
use Utd\AudioRoom\Models\CharismaLevel;
use Utd\AudioRoom\Models\CharismaRoomData;

/**
 * Internal-logic (non-HTTP) coverage for the audio-room package: entity role
 * helpers, blacklist ban/expiry value logic, category tree, charisma cache
 * invalidation + relationships, and the user-data contributor. HTTP endpoints
 * are already covered by EndpointCoverageTest / RoomMediaTest / RoomSecurityTest.
 */
class InternalLogicTest extends TestCase
{
    use RefreshDatabase;

    private function makeRoom(User $owner, array $attrs = []): Room
    {
        static $seq = 0;
        $seq++;

        return Room::create(array_merge([
            'num_id'    => 500000 + $seq,
            'user_id'   => $owner->id,
            'room_name' => 'Logic Room ' . $seq,
        ], $attrs));
    }

    // =====================================================================
    // Room — role helpers
    // =====================================================================

    public function test_is_owner(): void
    {
        $owner = User::factory()->create();
        $room = $this->makeRoom($owner);

        $this->assertTrue($room->isOwner($owner->id));
        $this->assertFalse($room->isOwner($owner->id + 999));
    }

    public function test_is_admin(): void
    {
        $owner = User::factory()->create();
        $admin = User::factory()->create();
        $room = $this->makeRoom($owner);
        RoomAdministrator::create([
            'room_id' => $room->id, 'user_id' => $admin->id,
            'assigned_by' => $owner->id, 'assigned_at' => now(),
        ]);

        $this->assertTrue($room->isAdmin($admin->id));
        $this->assertFalse($room->isAdmin($owner->id)); // owner is not an "admin" row
    }

    public function test_is_owner_or_admin(): void
    {
        $owner = User::factory()->create();
        $admin = User::factory()->create();
        $stranger = User::factory()->create();
        $room = $this->makeRoom($owner);
        RoomAdministrator::create([
            'room_id' => $room->id, 'user_id' => $admin->id,
            'assigned_by' => $owner->id, 'assigned_at' => now(),
        ]);

        $this->assertTrue($room->isOwnerOrAdmin($owner->id));
        $this->assertTrue($room->isOwnerOrAdmin($admin->id));
        $this->assertFalse($room->isOwnerOrAdmin($stranger->id));
    }

    public function test_has_password(): void
    {
        $owner = User::factory()->create();
        $locked = $this->makeRoom($owner, ['room_pass' => 'secret']);
        $open = $this->makeRoom($owner);

        $this->assertTrue($locked->hasPassword());
        $this->assertFalse($open->hasPassword());
    }

    public function test_room_pass_is_hidden_from_array(): void
    {
        $owner = User::factory()->create();
        $room = $this->makeRoom($owner, ['room_pass' => 'secret']);

        $this->assertArrayNotHasKey('room_pass', $room->toArray());
    }

    public function test_room_casts(): void
    {
        $owner = User::factory()->create();
        $room = $this->makeRoom($owner, [
            'mode' => '5', 'is_afk' => 1, 'is_comment_closed' => 0,
            'pinned_message' => ['text' => 'hi', 'timestamp' => 1],
        ]);
        $room->refresh();

        $this->assertSame(5, $room->mode);
        $this->assertIsInt($room->mode);
        $this->assertTrue($room->is_afk);
        $this->assertFalse($room->is_comment_closed);
        $this->assertSame('hi', $room->pinned_message['text']);
    }

    public function test_room_relationships(): void
    {
        $owner = User::factory()->create();
        $room = $this->makeRoom($owner);
        $visitor = User::factory()->create();
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $visitor->id]);
        RoomAdministrator::create([
            'room_id' => $room->id, 'user_id' => $visitor->id,
            'assigned_by' => $owner->id, 'assigned_at' => now(),
        ]);
        RoomBlacklist::create([
            'room_id' => $room->id, 'user_id' => $visitor->id,
            'banned_by' => $owner->id, 'banned_at' => now(), 'is_active' => true,
        ]);

        $room->refresh();
        $this->assertSame($owner->id, $room->owner->id);
        $this->assertCount(1, $room->visitors);
        $this->assertCount(1, $room->administrators);
        $this->assertCount(1, $room->blacklist);
    }

    // =====================================================================
    // RoomBlacklist — ban validity / expiry
    // =====================================================================

    public function test_blacklist_permanent_ban_is_valid(): void
    {
        $ban = new RoomBlacklist(['is_active' => true, 'expires_at' => null]);

        $this->assertFalse($ban->hasExpired());
        $this->assertTrue($ban->isValid());
        $this->assertNull($ban->getTimeRemaining());
    }

    public function test_blacklist_future_expiry_is_valid_with_time_remaining(): void
    {
        $ban = new RoomBlacklist([
            'is_active' => true,
            'expires_at' => now()->addMinutes(10),
        ]);

        $this->assertFalse($ban->hasExpired());
        $this->assertTrue($ban->isValid());
        $this->assertGreaterThan(0, $ban->getTimeRemaining());
        $this->assertLessThanOrEqual(600, $ban->getTimeRemaining());
    }

    public function test_blacklist_past_expiry_has_expired(): void
    {
        $ban = new RoomBlacklist([
            'is_active' => true,
            'expires_at' => now()->subMinute(),
        ]);

        $this->assertTrue($ban->hasExpired());
        $this->assertFalse($ban->isValid());
        $this->assertSame(0, $ban->getTimeRemaining());
    }

    public function test_blacklist_inactive_ban_is_not_valid(): void
    {
        $ban = new RoomBlacklist(['is_active' => false, 'expires_at' => null]);

        $this->assertFalse($ban->isValid());
    }

    public function test_blacklist_valid_scope_filters_active_and_unexpired(): void
    {
        $owner = User::factory()->create();
        $room = $this->makeRoom($owner);

        $active = User::factory()->create();
        $inactive = User::factory()->create();
        $expired = User::factory()->create();

        RoomBlacklist::create([
            'room_id' => $room->id, 'user_id' => $active->id,
            'banned_by' => $owner->id, 'banned_at' => now(), 'is_active' => true,
        ]);
        RoomBlacklist::create([
            'room_id' => $room->id, 'user_id' => $inactive->id,
            'banned_by' => $owner->id, 'banned_at' => now(), 'is_active' => false,
        ]);
        RoomBlacklist::create([
            'room_id' => $room->id, 'user_id' => $expired->id,
            'banned_by' => $owner->id, 'banned_at' => now(),
            'is_active' => true, 'expires_at' => now()->subMinute(),
        ]);

        $valid = RoomBlacklist::where('room_id', $room->id)->valid()->pluck('user_id')->all();

        $this->assertEqualsCanonicalizing([$active->id], $valid);
    }

    public function test_blacklist_casts_datetimes_and_boolean(): void
    {
        $owner = User::factory()->create();
        $room = $this->makeRoom($owner);
        $banned = User::factory()->create();
        $ban = RoomBlacklist::create([
            'room_id' => $room->id, 'user_id' => $banned->id,
            'banned_by' => $owner->id, 'banned_at' => now(),
            'expires_at' => now()->addHour(), 'is_active' => 1,
        ]);
        $ban->refresh();

        $this->assertInstanceOf(Carbon::class, $ban->banned_at);
        $this->assertInstanceOf(Carbon::class, $ban->expires_at);
        $this->assertIsBool($ban->is_active);
        $this->assertTrue($ban->is_active);
    }

    // =====================================================================
    // RoomCategory — tree
    // =====================================================================

    public function test_category_children_ordered_by_sort(): void
    {
        $parent = RoomCategory::create(['name' => 'Music', 'enable' => true, 'sort' => 1]);
        RoomCategory::create(['name' => 'B', 'parent_id' => $parent->id, 'enable' => true, 'sort' => 2]);
        RoomCategory::create(['name' => 'A', 'parent_id' => $parent->id, 'enable' => true, 'sort' => 1]);

        $names = $parent->children->pluck('name')->all();

        $this->assertSame(['A', 'B'], $names);
    }

    public function test_category_parent_relationship(): void
    {
        $parent = RoomCategory::create(['name' => 'Music', 'enable' => true, 'sort' => 1]);
        $child = RoomCategory::create(['name' => 'Pop', 'parent_id' => $parent->id, 'enable' => true, 'sort' => 1]);

        $this->assertSame($parent->id, $child->parent->id);
    }

    public function test_category_enable_cast_is_boolean(): void
    {
        $cat = RoomCategory::create(['name' => 'X', 'enable' => 1, 'sort' => 1]);
        $cat->refresh();

        $this->assertIsBool($cat->enable);
        $this->assertTrue($cat->enable);
    }

    public function test_category_rooms_relationship(): void
    {
        $owner = User::factory()->create();
        $cat = RoomCategory::create(['name' => 'Talk', 'enable' => true, 'sort' => 1]);
        $this->makeRoom($owner, ['room_type' => $cat->id]);

        $this->assertCount(1, $cat->rooms);
    }

    // =====================================================================
    // CharismaLevel — cache invalidation
    // =====================================================================

    public function test_charisma_level_save_forgets_cache(): void
    {
        Cache::put('charisma_levels', 'stale', 60);

        CharismaLevel::create(['level' => 1, 'points' => 100, 'image' => 'l1.png']);

        $this->assertFalse(Cache::has('charisma_levels'));
    }

    public function test_charisma_level_delete_forgets_cache(): void
    {
        $level = CharismaLevel::create(['level' => 2, 'points' => 200, 'image' => 'l2.png']);
        Cache::put('charisma_levels', 'stale', 60);

        $level->delete();

        $this->assertFalse(Cache::has('charisma_levels'));
    }

    // =====================================================================
    // CharismaRoomData — relationships
    // =====================================================================

    public function test_charisma_room_data_relationships(): void
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $room = $this->makeRoom($owner);
        $row = CharismaRoomData::create(['room_id' => $room->id, 'user_id' => $user->id, 'total' => 42]);

        $this->assertSame($room->id, $row->room->id);
        $this->assertSame($user->id, $row->user->id);
    }

    // =====================================================================
    // AudioRoomDataContributor
    // =====================================================================

    public function test_user_data_contributor_key(): void
    {
        $this->assertSame('audio_room', (new AudioRoomDataContributor())->getKey());
    }

    public function test_user_data_contributor_reports_no_room(): void
    {
        $user = User::factory()->create();

        $data = (new AudioRoomDataContributor())->getUserData($user);

        $this->assertFalse($data['has_room']);
        $this->assertNull($data['room_id']);
        $this->assertNull($data['room_name']);
    }

    public function test_user_data_contributor_reports_audio_room(): void
    {
        $owner = User::factory()->create();
        $room = $this->makeRoom($owner, ['type' => 'audio', 'room_name' => 'My Audio Room']);

        $data = (new AudioRoomDataContributor())->getUserData($owner);

        $this->assertTrue($data['has_room']);
        $this->assertSame($room->id, $data['room_id']);
        $this->assertSame('My Audio Room', $data['room_name']);
    }

    public function test_user_data_contributor_ignores_non_audio_room(): void
    {
        $owner = User::factory()->create();
        // A room that is NOT type=audio must not count as the user's audio room.
        $this->makeRoom($owner, ['type' => 'video']);

        $data = (new AudioRoomDataContributor())->getUserData($owner);

        $this->assertFalse($data['has_room']);
    }

    // =====================================================================
    // RoomOwnerResolver binding (gifts room-owner cut, IDOR guard)
    // =====================================================================

    public function test_room_owner_resolver_returns_owner_id(): void
    {
        $resolver = app(\App\Contracts\RoomOwnerResolver::class);
        $owner = User::factory()->create();
        $room = $this->makeRoom($owner);

        $this->assertSame($owner->id, $resolver->ownerId($room->id));
        $this->assertNull($resolver->ownerId(999999));
    }
}
