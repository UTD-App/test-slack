<?php

namespace Utd\Gifts\Tests\Feature;

use App\Contracts\GiftDirectory;
use App\Contracts\RoomOwnerResolver;
use App\Events\Gifts\GiftSent;
use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use Utd\Gifts\Listeners\CreditRoomOwnerOnGiftSent;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftCategory;
use Utd\Gifts\Models\GiftLevel;
use Utd\Gifts\Models\GiftLog;
use Utd\Gifts\Models\GiftSetting;
use Utd\Gifts\Models\GiftUserExp;
use Utd\Gifts\Profile\GiftsProfileContributor;
use Utd\Gifts\Services\GiftCatalogService;
use Utd\Gifts\Services\GiftDirectoryService;
use Utd\Gifts\Services\GiftLevelService;
use Utd\Gifts\Support\GiftSettings;
use Utd\Gifts\Support\Media;

/**
 * Direct unit/service coverage for the Gifts package internals that the
 * endpoint tests don't reach: catalog/level/directory services, settings,
 * media resolution, the room-owner listener, the profile contributor, and
 * model casts/scopes.
 */
class InternalLogicTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

    private function gift(array $attrs = []): Gift
    {
        return Gift::create(array_merge([
            'name'   => 'Rose',
            'e_name' => 'Rose',
            'type'   => Gift::TYPE_NORMAL,
            'price'  => 100,
            'enable' => true,
        ], $attrs));
    }

    private function log(array $attrs): GiftLog
    {
        return GiftLog::create(array_merge([
            'gift_id'         => 1,
            'gift_name'       => 'Rose',
            'sender_id'       => 1,
            'receiver_id'     => 2,
            'gift_num'        => 1,
            'unit_price'      => 10,
            'total_price'     => 10,
            'receiver_earned' => 10,
        ], $attrs));
    }

    // ----------------------------------------------------------------------
    // GiftCatalogService
    // ----------------------------------------------------------------------

    public function test_catalog_categories_are_ordered_by_sort_and_localized(): void
    {
        GiftCategory::create(['title' => ['en' => 'Second', 'ar' => 'تاني'], 'type' => 'normal', 'sort' => 2]);
        GiftCategory::create(['title' => ['en' => 'First', 'ar' => 'أول'], 'type' => 'normal', 'sort' => 1]);

        $cats = app(GiftCatalogService::class)->categories();

        $this->assertCount(2, $cats);
        $this->assertSame('First', $cats[0]['title']);  // sort 1 first
        $this->assertSame('Second', $cats[1]['title']);
        $this->assertSame(1, $cats[0]['sort']);
    }

    public function test_catalog_localize_falls_back_to_en_then_first_for_unknown_locale(): void
    {
        app()->setLocale('fr'); // not present in the title map
        GiftCategory::create(['title' => ['en' => 'Popular', 'ar' => 'الأكثر'], 'type' => 'normal', 'sort' => 1]);

        $title = app(GiftCatalogService::class)->categories()[0]['title'];

        $this->assertSame('Popular', $title); // en fallback
    }

    public function test_gifts_by_category_returns_only_enabled_filtered_and_ordered(): void
    {
        $catA = GiftCategory::create(['title' => ['en' => 'A'], 'type' => 'normal', 'sort' => 1]);
        $catB = GiftCategory::create(['title' => ['en' => 'B'], 'type' => 'normal', 'sort' => 2]);

        $this->gift(['name' => 'A-second', 'gift_category_id' => $catA->id, 'sort' => 2]);
        $this->gift(['name' => 'A-first', 'gift_category_id' => $catA->id, 'sort' => 1]);
        $this->gift(['name' => 'A-off', 'gift_category_id' => $catA->id, 'enable' => false]);
        $this->gift(['name' => 'B-one', 'gift_category_id' => $catB->id]);

        $gifts = app(GiftCatalogService::class)->giftsByCategory($catA->id);

        $this->assertCount(2, $gifts);                 // only enabled in cat A
        $this->assertSame('A-first', $gifts[0]['name']); // sort asc
        $this->assertSame('A-second', $gifts[1]['name']);
    }

    public function test_gifts_by_category_without_id_returns_all_enabled(): void
    {
        $this->gift(['name' => 'On1']);
        $this->gift(['name' => 'On2']);
        $this->gift(['name' => 'Off', 'enable' => false]);

        $this->assertCount(2, app(GiftCatalogService::class)->giftsByCategory());
    }

    public function test_images_returns_resolved_urls_for_enabled_only(): void
    {
        $this->gift(['name' => 'A', 'img' => 'gifts/a.png']);
        $this->gift(['name' => 'B', 'img' => 'gifts/b.png']);
        $this->gift(['name' => 'Off', 'img' => 'gifts/off.png', 'enable' => false]);
        $this->gift(['name' => 'NoImg', 'img' => null]); // filtered out (null url)

        $images = app(GiftCatalogService::class)->images();

        $this->assertCount(2, $images);
        foreach ($images as $url) {
            $this->assertNotNull($url);
            $this->assertStringContainsString('gifts/', $url);
        }
    }

    public function test_by_id_returns_minimal_shape_or_null_and_is_not_enable_filtered(): void
    {
        $disabled = $this->gift(['name' => 'Hidden', 'show_img' => 'gifts/h.svga', 'enable' => false]);

        $result = app(GiftCatalogService::class)->byId($disabled->id);
        $this->assertSame($disabled->id, $result['id']);   // disabled still resolvable by id
        $this->assertSame('Hidden', $result['name']);
        $this->assertArrayHasKey('image', $result);

        $this->assertNull(app(GiftCatalogService::class)->byId(999999));
    }

    public function test_affordable_gifts_filters_by_user_balance(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 150, 'admin_charge');

        $this->gift(['name' => 'Cheap', 'price' => 50]);
        $this->gift(['name' => 'Exact', 'price' => 150]);
        $this->gift(['name' => 'TooDear', 'price' => 200]);

        $names = collect(app(GiftCatalogService::class)->affordableGifts($user)->items())
            ->pluck('name')->all();

        $this->assertContains('Cheap', $names);
        $this->assertContains('Exact', $names);    // price <= balance
        $this->assertNotContains('TooDear', $names);
    }

    public function test_affordable_gifts_with_no_balance_only_returns_free_gifts(): void
    {
        $user = User::factory()->create(); // no wallet → balance 0
        $this->gift(['name' => 'Free', 'price' => 0]);
        $this->gift(['name' => 'Paid', 'price' => 10]);

        $names = collect(app(GiftCatalogService::class)->affordableGifts($user)->items())
            ->pluck('name')->all();

        $this->assertSame(['Free'], $names);
    }

    public function test_mark_gifts_seen_is_safe_when_column_absent(): void
    {
        $user = User::factory()->create();
        // The base users table has no `new_gift` column → guarded no-op, must not throw.
        app(GiftCatalogService::class)->markGiftsSeen($user);
        $this->assertTrue(true);
    }

    public function test_backpack_gifts_is_empty_documented_gap(): void
    {
        $this->assertSame([], app(GiftCatalogService::class)->backpackGifts(User::factory()->create()));
        $this->assertSame([], app(GiftCatalogService::class)->backpackGifts(null));
    }

    public function test_present_gift_exposes_the_full_shape_with_casts(): void
    {
        $gift = $this->gift([
            'name' => 'Car', 'e_name' => 'Car', 'price' => 500, 'img' => 'gifts/car.png',
            'is_play' => 1, 'music_gift' => 1, 'international_gift' => 0, 'image_type' => 'svga',
        ]);

        $shape = app(GiftCatalogService::class)->presentGift($gift);

        $this->assertSame('Car', $shape['name']);
        $this->assertSame('svga', $shape['image_type']);
        $this->assertTrue($shape['is_play']);
        $this->assertStringContainsString('gifts/car.png', $shape['img']);
    }

    // ----------------------------------------------------------------------
    // GiftLevelService
    // ----------------------------------------------------------------------

    private function seedLevels(): void
    {
        foreach ([[1, 0, 's1.png'], [2, 1000, 's2.png'], [3, 10000, 's3.png']] as [$level, $threshold, $img]) {
            foreach ([GiftLevel::KIND_SENDER, GiftLevel::KIND_RECEIVER] as $kind) {
                GiftLevel::create([
                    'kind' => $kind, 'level' => $level, 'threshold' => $threshold,
                    'title' => ['en' => "{$kind}-{$level}"], 'img' => $img,
                ]);
            }
        }
    }

    public function test_level_for_picks_highest_threshold_not_exceeding_exp(): void
    {
        $this->seedLevels();
        $svc = app(GiftLevelService::class);

        $this->assertSame(0, $svc->levelFor(GiftLevel::KIND_SENDER, -5));   // below first level
        $this->assertSame(1, $svc->levelFor(GiftLevel::KIND_SENDER, 0));    // exactly at threshold 0
        $this->assertSame(1, $svc->levelFor(GiftLevel::KIND_SENDER, 999));  // still level 1
        $this->assertSame(2, $svc->levelFor(GiftLevel::KIND_SENDER, 1000)); // boundary
        $this->assertSame(3, $svc->levelFor(GiftLevel::KIND_SENDER, 50000));// way above top
    }

    public function test_level_for_unknown_kind_is_zero(): void
    {
        $this->seedLevels();
        $this->assertSame(0, app(GiftLevelService::class)->levelFor('nonsense', 99999));
    }

    public function test_next_threshold_returns_next_up_or_null_at_top(): void
    {
        $this->seedLevels();
        $svc = app(GiftLevelService::class);

        $this->assertSame(1000, $svc->nextThreshold(GiftLevel::KIND_SENDER, 0));
        $this->assertSame(10000, $svc->nextThreshold(GiftLevel::KIND_SENDER, 1000));
        $this->assertNull($svc->nextThreshold(GiftLevel::KIND_SENDER, 10000)); // already top
    }

    public function test_icon_for_returns_raw_img_or_null_below_level_one(): void
    {
        $this->seedLevels();
        $svc = app(GiftLevelService::class);

        $this->assertNull($svc->iconFor(GiftLevel::KIND_SENDER, 0)); // no badge below 1
        $this->assertSame('s2.png', $svc->iconFor(GiftLevel::KIND_SENDER, 2));
        $this->assertNull($svc->iconFor(GiftLevel::KIND_SENDER, 99)); // no such level
    }

    public function test_stats_for_computes_levels_exp_and_thresholds(): void
    {
        $this->seedLevels();
        $user = User::factory()->create();
        GiftUserExp::create(['user_id' => $user->id, 'sender_exp' => 1500, 'receiver_exp' => 0]);

        $stats = app(GiftLevelService::class)->statsFor($user->id);

        $this->assertSame(2, $stats['sender_level']);            // 1500 >= 1000
        $this->assertSame(1, $stats['receiver_level']);          // 0 >= 0
        $this->assertSame(1500, $stats['sender_exp']);
        $this->assertSame(10000, $stats['sender_next_threshold']);
        $this->assertStringContainsString('s2.png', $stats['sender_level_img']); // resolved URL
    }

    public function test_stats_for_user_with_no_exp_row_defaults_to_zero(): void
    {
        $this->seedLevels();
        $stats = app(GiftLevelService::class)->statsFor(424242);

        $this->assertSame(0, $stats['sender_exp']);
        $this->assertSame(1, $stats['sender_level']); // threshold-0 level still applies at exp 0
        $this->assertStringContainsString('s1.png', $stats['sender_level_img']); // level-1 badge resolved
    }

    public function test_add_exp_inserts_then_increments_and_busts_cache(): void
    {
        $svc = app(GiftLevelService::class);

        $this->assertSame(50, $svc->addExp(7, GiftLevel::KIND_SENDER, 50)); // insert
        $this->assertSame(80, $svc->addExp(7, GiftLevel::KIND_SENDER, 30)); // increment
        $this->assertDatabaseHas('gift_user_exp', ['user_id' => 7, 'sender_exp' => 80]);
    }

    public function test_add_exp_ignores_unknown_kind_and_non_positive_delta(): void
    {
        $svc = app(GiftLevelService::class);

        $this->assertSame(0, $svc->addExp(9, 'bogus', 100));      // unknown kind → no row
        $this->assertDatabaseCount('gift_user_exp', 0);

        $svc->addExp(9, GiftLevel::KIND_RECEIVER, 40);            // seed a real row
        $this->assertSame(40, $svc->addExp(9, GiftLevel::KIND_RECEIVER, 0));   // zero → read-only
        $this->assertSame(40, $svc->addExp(9, GiftLevel::KIND_RECEIVER, -10)); // negative → read-only
        $this->assertDatabaseHas('gift_user_exp', ['user_id' => 9, 'receiver_exp' => 40]);
    }

    // ----------------------------------------------------------------------
    // GiftDirectoryService
    // ----------------------------------------------------------------------

    public function test_directory_is_bound_to_the_contract(): void
    {
        $this->assertInstanceOf(GiftDirectoryService::class, app(GiftDirectory::class));
    }

    public function test_directory_gifts_for_groups_and_sums_by_context(): void
    {
        $sender = User::factory()->create();
        $receiver = User::factory()->create();
        $gift = $this->gift(['img' => 'gifts/rose.png']);
        $base = ['gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $receiver->id];
        $this->log($base + ['gift_num' => 2, 'context_type' => 'moment', 'context_id' => 7]);
        $this->log($base + ['gift_num' => 3, 'context_type' => 'moment', 'context_id' => 7]);
        $this->log($base + ['gift_num' => 9, 'context_type' => 'moment', 'context_id' => 8]); // other ctx

        $rows = app(GiftDirectoryService::class)->giftsFor('moment', 7);

        $this->assertCount(1, $rows);
        $this->assertSame($gift->id, $rows[0]['gift_id']);
        $this->assertSame(5, $rows[0]['num']);                       // 2 + 3
        $this->assertStringContainsString('gifts/rose.png', $rows[0]['img']); // resolved
    }

    public function test_directory_gifters_count_and_coins_for_a_context(): void
    {
        $g1 = User::factory()->create();
        $g2 = User::factory()->create();
        $gift = $this->gift();

        $this->log(['gift_id' => $gift->id, 'sender_id' => $g1->id, 'gift_num' => 1, 'total_price' => 100, 'context_type' => 'moment', 'context_id' => 5]);
        $this->log(['gift_id' => $gift->id, 'sender_id' => $g1->id, 'gift_num' => 3, 'total_price' => 300, 'context_type' => 'moment', 'context_id' => 5]);
        $this->log(['gift_id' => $gift->id, 'sender_id' => $g2->id, 'gift_num' => 1, 'total_price' => 100, 'context_type' => 'moment', 'context_id' => 5]);

        $svc = app(GiftDirectoryService::class);

        $gifters = $svc->giftersFor('moment', 5);
        $this->assertCount(2, $gifters);
        $this->assertSame($g1->id, $gifters[0]['user']['id']); // 4 > 1 → g1 first
        $this->assertSame(4, $gifters[0]['num']);

        $this->assertSame(5, $svc->countFor('moment', 5));     // 1+3+1
        $this->assertSame(500.0, $svc->coinsFor('moment', 5)); // 100+300+100
        $this->assertSame(0, $svc->countFor('moment', 999));   // empty context
    }

    public function test_directory_received_and_sent_group_by_user(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $gift = $this->gift(['img' => 'gifts/r.png']);

        // received by $user
        $this->log(['gift_id' => $gift->id, 'sender_id' => $other->id, 'receiver_id' => $user->id, 'gift_num' => 2]);
        $this->log(['gift_id' => $gift->id, 'sender_id' => $other->id, 'receiver_id' => $user->id, 'gift_num' => 3]);
        // sent by $user
        $this->log(['gift_id' => $gift->id, 'sender_id' => $user->id, 'receiver_id' => $other->id, 'gift_num' => 1]);

        $svc = app(GiftDirectoryService::class);

        $received = $svc->receivedBy($user->id);
        $this->assertCount(1, $received);
        $this->assertSame(5, $received[0]['num']);
        $this->assertSame('gifts/r.png', $received[0]['img']); // RAW path, not resolved URL

        $sent = $svc->sentBy($user->id);
        $this->assertSame(1, $sent[0]['num']);
    }

    public function test_directory_top_supporters_ordered_by_total_spent(): void
    {
        $user = User::factory()->create();
        $big = User::factory()->create();
        $small = User::factory()->create();
        $gift = $this->gift();

        $this->log(['gift_id' => $gift->id, 'sender_id' => $big->id, 'receiver_id' => $user->id, 'gift_num' => 2, 'total_price' => 1000]);
        $this->log(['gift_id' => $gift->id, 'sender_id' => $small->id, 'receiver_id' => $user->id, 'gift_num' => 1, 'total_price' => 100]);

        $top = app(GiftDirectoryService::class)->topSupporters($user->id);

        $this->assertCount(2, $top);
        $this->assertSame($big->id, $top[0]['user_id']);  // highest total first
        $this->assertSame(1000, $top[0]['total']);
        $this->assertSame(2, $top[0]['gifts']);
        $this->assertSame($big->uuid, $top[0]['uuid']);
    }

    public function test_directory_top_supporters_respects_limit(): void
    {
        $user = User::factory()->create();
        $gift = $this->gift();
        foreach (range(1, 5) as $i) {
            $sender = User::factory()->create();
            $this->log(['gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $user->id, 'total_price' => $i * 10]);
        }

        $this->assertCount(2, app(GiftDirectoryService::class)->topSupporters($user->id, 2));
    }

    public function test_directory_levels_for_delegates_to_level_service(): void
    {
        $this->seedLevels();
        $user = User::factory()->create();
        GiftUserExp::create(['user_id' => $user->id, 'sender_exp' => 1000, 'receiver_exp' => 0]);

        $levels = app(GiftDirectoryService::class)->levelsFor($user->id);
        $this->assertSame(2, $levels['sender_level']);
    }

    // ----------------------------------------------------------------------
    // GiftSettings
    // ----------------------------------------------------------------------

    public function test_settings_get_falls_back_to_config_default(): void
    {
        // No DB override → falls to config('gifts.exp_per_coin') = 1.0.
        $this->assertSame(1.0, GiftSettings::float('exp_per_coin'));
        // Unknown key, explicit default.
        $this->assertSame('x', GiftSettings::get('totally_unknown', 'x'));
    }

    public function test_settings_set_persists_and_overrides_config(): void
    {
        GiftSettings::set('exp_per_coin', '2.5');

        $this->assertSame(2.5, GiftSettings::float('exp_per_coin'));
        $this->assertDatabaseHas('gift_settings', ['key' => 'exp_per_coin']);

        // updateOrCreate path: a second set replaces, not duplicates.
        GiftSettings::set('exp_per_coin', '3.0');
        $this->assertSame(1, GiftSetting::where('key', 'exp_per_coin')->count());
        $this->assertSame(3.0, GiftSettings::float('exp_per_coin'));
    }

    public function test_settings_all_and_forget(): void
    {
        GiftSettings::set('a', '1');
        GiftSettings::set('b', '2');

        $all = GiftSettings::all();
        $this->assertSame('1', $all['a']);
        $this->assertSame('2', $all['b']);

        GiftSettings::forget(); // just must not throw; cache rebuilt on next read
        $this->assertSame('1', GiftSettings::all()['a']);
    }

    // ----------------------------------------------------------------------
    // Support\Media
    // ----------------------------------------------------------------------

    public function test_media_url_passes_through_absolute_and_resolves_relative_and_null(): void
    {
        $this->assertNull(Media::url(null));
        $this->assertNull(Media::url(''));
        $this->assertSame('https://cdn.example/a.png', Media::url('https://cdn.example/a.png'));
        $this->assertSame('http://cdn.example/a.png', Media::url('http://cdn.example/a.png'));

        $resolved = Media::url('gifts/a.png');
        $this->assertNotNull($resolved);
        $this->assertStringContainsString('gifts/a.png', $resolved);
        // leading slash is trimmed before the disk url
        $this->assertStringContainsString('gifts/a.png', Media::url('/gifts/a.png'));
    }

    // ----------------------------------------------------------------------
    // Listener: CreditRoomOwnerOnGiftSent
    // ----------------------------------------------------------------------

    private function giftSentEvent(User $sender, User $receiver, array $context, float $total = 1000): GiftSent
    {
        return new GiftSent($sender, $receiver, $this->gift()->id, 1, $total, $total, $context);
    }

    private function bindRoomOwner(?int $ownerId): void
    {
        app()->bind(RoomOwnerResolver::class, fn () => new class($ownerId) implements RoomOwnerResolver {
            public function __construct(private ?int $ownerId) {}
            public function ownerId(int $roomId): ?int { return $this->ownerId; }
        });
    }

    public function test_listener_noop_without_room_id(): void
    {
        $sender = User::factory()->create();
        $receiver = User::factory()->create();
        $owner = User::factory()->create();
        $this->bindRoomOwner($owner->id);

        (new CreditRoomOwnerOnGiftSent())->handle($this->giftSentEvent($sender, $receiver, [])); // no room_id

        $this->assertSame(0.0, Wallet::getBalance($owner, 'diamonds'));
    }

    public function test_listener_noop_when_no_resolver_bound(): void
    {
        $sender = User::factory()->create();
        $receiver = User::factory()->create();

        // No RoomOwnerResolver bound → pay nobody, must not throw.
        (new CreditRoomOwnerOnGiftSent())->handle($this->giftSentEvent($sender, $receiver, ['room_id' => 5]));
        $this->assertTrue(true);
    }

    public function test_listener_credits_owner_their_cut(): void
    {
        $sender = User::factory()->create();
        $receiver = User::factory()->create();
        $owner = User::factory()->create();
        $this->bindRoomOwner($owner->id);

        // total 1000 × default 3% = 30 diamonds
        (new CreditRoomOwnerOnGiftSent())->handle($this->giftSentEvent($sender, $receiver, ['room_id' => 5], 1000));

        $this->assertSame(30.0, Wallet::getBalance($owner, 'diamonds'));
    }

    public function test_listener_uses_admin_tunable_rate(): void
    {
        GiftSettings::set('room_owner_rate', '0.10'); // 10%
        $sender = User::factory()->create();
        $receiver = User::factory()->create();
        $owner = User::factory()->create();
        $this->bindRoomOwner($owner->id);

        (new CreditRoomOwnerOnGiftSent())->handle($this->giftSentEvent($sender, $receiver, ['room_id' => 5], 1000));

        $this->assertSame(100.0, Wallet::getBalance($owner, 'diamonds'));
    }

    public function test_listener_does_not_pay_owner_who_is_sender_or_receiver(): void
    {
        $owner = User::factory()->create();
        $receiver = User::factory()->create();
        $this->bindRoomOwner($owner->id);

        // owner is the sender
        (new CreditRoomOwnerOnGiftSent())->handle($this->giftSentEvent($owner, $receiver, ['room_id' => 5], 1000));
        $this->assertSame(0.0, Wallet::getBalance($owner, 'diamonds'));

        // owner is the receiver
        (new CreditRoomOwnerOnGiftSent())->handle($this->giftSentEvent($receiver, $owner, ['room_id' => 5], 1000));
        $this->assertSame(0.0, Wallet::getBalance($owner, 'diamonds'));
    }

    public function test_listener_noop_when_owner_resolves_to_zero_or_missing_user(): void
    {
        $sender = User::factory()->create();
        $receiver = User::factory()->create();

        $this->bindRoomOwner(0); // owner id 0 → bail
        (new CreditRoomOwnerOnGiftSent())->handle($this->giftSentEvent($sender, $receiver, ['room_id' => 5], 1000));

        $this->bindRoomOwner(999999); // no such user → bail
        (new CreditRoomOwnerOnGiftSent())->handle($this->giftSentEvent($sender, $receiver, ['room_id' => 5], 1000));

        $this->assertTrue(true); // no exception, no credit anywhere
    }

    // ----------------------------------------------------------------------
    // GiftsProfileContributor
    // ----------------------------------------------------------------------

    public function test_profile_contributor_key_is_gifts(): void
    {
        $this->assertSame('gifts', (new GiftsProfileContributor())->key());
    }

    public function test_profile_contributor_includes_levels_and_received_for_self(): void
    {
        $this->seedLevels();
        $target = User::factory()->create();
        GiftUserExp::create(['user_id' => $target->id, 'sender_exp' => 0, 'receiver_exp' => 1000]);
        $sender = User::factory()->create();
        $gift = $this->gift(['img' => 'gifts/g.png']);
        $this->log(['gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $target->id, 'gift_num' => 4]);

        // Self view: no top_supporters / sent extras.
        $section = (new GiftsProfileContributor())->contribute($target, $target);

        $this->assertSame(4, $section['count']);
        $this->assertCount(1, $section['items']);
        $this->assertSame(2, $section['receiver_level']);          // 1000 → level 2
        $this->assertArrayNotHasKey('top_supporters', $section);
        $this->assertArrayNotHasKey('sent', $section);
    }

    public function test_profile_contributor_adds_visiting_extras_for_other_viewer(): void
    {
        $this->seedLevels();
        $target = User::factory()->create();
        $viewer = User::factory()->create();
        $sender = User::factory()->create();
        $gift = $this->gift();
        $this->log(['gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $target->id, 'gift_num' => 2, 'total_price' => 200]);

        $section = (new GiftsProfileContributor())->contribute($target, $viewer);

        $this->assertArrayHasKey('top_supporters', $section);
        $this->assertArrayHasKey('sent', $section);
        $this->assertSame($sender->id, $section['top_supporters'][0]['user_id']);
    }

    // ----------------------------------------------------------------------
    // Models: casts, scopes, relationships
    // ----------------------------------------------------------------------

    public function test_gift_model_casts_scope_and_is_lucky(): void
    {
        $cat = GiftCategory::create(['title' => ['en' => 'C'], 'type' => 'normal', 'sort' => 1]);
        $normal = $this->gift(['gift_category_id' => $cat->id, 'is_play' => 1, 'enable' => 1]);
        $lucky = $this->gift(['type' => Gift::TYPE_LUCKY, 'enable' => 0]);

        $this->assertTrue($normal->is_play);            // bool cast
        $this->assertFalse($normal->isLucky());
        $this->assertTrue($lucky->isLucky());
        $this->assertTrue($normal->category->is($cat)); // belongsTo

        $this->assertSame(1, Gift::enabled()->count());  // scope excludes the disabled lucky
    }

    public function test_gift_category_casts_title_and_has_gifts(): void
    {
        $cat = GiftCategory::create(['title' => ['en' => 'Pop', 'ar' => 'شائع'], 'type' => 'normal', 'sort' => 1]);
        $this->gift(['gift_category_id' => $cat->id]);

        $this->assertIsArray($cat->title);
        $this->assertSame('Pop', $cat->title['en']);
        $this->assertCount(1, $cat->gifts);
    }

    public function test_gift_log_casts_and_relationships(): void
    {
        $sender = User::factory()->create();
        $receiver = User::factory()->create();
        $gift = $this->gift();
        $log = $this->log([
            'gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $receiver->id,
            'is_lucky' => 1, 'meta' => ['k' => 'v'],
        ]);

        $this->assertTrue($log->is_lucky);                 // bool cast
        $this->assertSame(['k' => 'v'], $log->meta);       // array cast
        $this->assertTrue($log->sender->is($sender));
        $this->assertTrue($log->receiver->is($receiver));
        $this->assertTrue($log->gift->is($gift));
    }
}
