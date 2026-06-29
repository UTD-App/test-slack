<?php

namespace Utd\Profile\Tests\Feature;

use App\Contracts\GiftDirectory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Profile\Filament\ProfileInfolist;
use Utd\Profile\Providers\ProfileServiceProvider;

/**
 * Internal-logic (non-HTTP) coverage for the Profile package: the admin
 * ProfileInfolist's pure view-data builder + number formatter, and the service
 * provider's menu/manifest declarations. The HTTP profile endpoint is already
 * covered by EndpointCoverageTest.
 */
class InternalLogicTest extends TestCase
{
    use RefreshDatabase;

    // =====================================================================
    // ProfileInfolist::fmt — K/M number formatting
    // =====================================================================

    public function test_fmt_small_numbers_pass_through(): void
    {
        $this->assertSame('0', ProfileInfolist::fmt(0));
        $this->assertSame('0', ProfileInfolist::fmt(null));
        $this->assertSame('999', ProfileInfolist::fmt(999));
    }

    public function test_fmt_thousands(): void
    {
        $this->assertSame('1K', ProfileInfolist::fmt(1000));
        $this->assertSame('1.5K', ProfileInfolist::fmt(1500));
        $this->assertSame('12.3K', ProfileInfolist::fmt(12345));
    }

    public function test_fmt_millions(): void
    {
        $this->assertSame('1M', ProfileInfolist::fmt(1_000_000));
        $this->assertSame('2.5M', ProfileInfolist::fmt(2_500_000));
    }

    // =====================================================================
    // ProfileInfolist::data — flattened view-ready data
    // =====================================================================

    public function test_data_returns_core_identity(): void
    {
        $user = User::factory()->create(['name' => 'Profile User']);
        $user->profile()->updateOrCreate(['user_id' => $user->id], ['gender' => 2]);

        $data = ProfileInfolist::data($user->fresh());

        $this->assertSame($user->id, $data['id']);
        $this->assertSame('Profile User', $data['name']);
        $this->assertSame(2, $data['gender']);
        $this->assertArrayHasKey('levels', $data);
        $this->assertArrayHasKey('supporters', $data);
        $this->assertArrayHasKey('friends', $data);
        // No social package installed in this harness → stats row omitted.
        $this->assertSame([], $data['stats']);
    }

    public function test_data_resolves_avatar_to_web_url(): void
    {
        $user = User::factory()->create();
        $user->profile()->updateOrCreate(['user_id' => $user->id], ['avatar' => 'avatars/x.jpg']);

        $data = ProfileInfolist::data($user->fresh());

        $this->assertNotSame('avatars/x.jpg', $data['avatar'], 'avatar must not be a raw path');
        $this->assertStringContainsString('avatars/x.jpg', (string) $data['avatar']);
    }

    public function test_data_resolves_covers_array(): void
    {
        $user = User::factory()->create();
        $user->profile()->updateOrCreate(
            ['user_id' => $user->id],
            ['covers' => ['covers/a.jpg', 'https://cdn.example.com/b.jpg']],
        );

        $data = ProfileInfolist::data($user->fresh());

        $this->assertCount(2, $data['covers']);
        $this->assertStringContainsString('covers/a.jpg', $data['covers'][0]);
        // Absolute URL passes through unchanged.
        $this->assertSame('https://cdn.example.com/b.jpg', $data['covers'][1]);
    }

    public function test_data_empty_covers_yields_empty_array(): void
    {
        $user = User::factory()->create();
        $user->profile()->updateOrCreate(['user_id' => $user->id], []);

        $data = ProfileInfolist::data($user->fresh());

        $this->assertSame([], $data['covers']);
    }

    public function test_data_pulls_gift_levels_and_supporters_when_bound(): void
    {
        $user = User::factory()->create();

        app()->bind(GiftDirectory::class, fn () => new class implements GiftDirectory {
            public function giftsFor(string $type, int $id): array { return []; }
            public function giftersFor(string $type, int $id): array { return []; }
            public function receiversFor(string $type, int $id): array { return []; }
            public function countFor(string $type, int $id): int { return 0; }
            public function coinsFor(string $type, int $id): float { return 0; }
            public function receivedBy(int $userId): array { return []; }
            public function sentBy(int $userId): array { return []; }
            public function topSupporters(int $userId, int $limit = 6): array
            {
                return [['user_id' => 7, 'name' => 'Top Fan', 'total' => 500, 'avatar' => 'avatars/fan.jpg']];
            }
            public function levelsFor(int $userId): array
            {
                return [
                    'sender_level' => 3, 'receiver_level' => 5,
                    'sender_level_img' => 'levels/s3.png', 'receiver_level_img' => 'levels/r5.png',
                ];
            }
        });

        $data = ProfileInfolist::data($user->fresh());

        $this->assertSame(3, $data['levels']['sender']);
        $this->assertSame(5, $data['levels']['receiver']);
        $this->assertStringContainsString('levels/s3.png', (string) $data['levels']['sender_img']);

        $this->assertCount(1, $data['supporters']);
        $this->assertSame(7, $data['supporters'][0]['user_id']);
        $this->assertSame('Top Fan', $data['supporters'][0]['name']);
        $this->assertSame(500, $data['supporters'][0]['total']);
        $this->assertStringContainsString('avatars/fan.jpg', (string) $data['supporters'][0]['avatar']);
        // The supporter links to that user's own dashboard profile.
        $this->assertStringContainsString('/users/7', (string) $data['supporters'][0]['url']);
    }

    // =====================================================================
    // ProfileServiceProvider — declarations
    // =====================================================================

    public function test_provider_package_slug(): void
    {
        $provider = new ProfileServiceProvider($this->app);

        $this->assertSame('profile', $provider->packageSlug());
        $this->assertSame('profile', $provider->getPackage());
    }

    public function test_provider_package_manifest(): void
    {
        $provider = new ProfileServiceProvider($this->app);
        $manifest = $provider->packageManifest();

        $this->assertSame('Profile', $manifest['name']);
        $this->assertFalse($manifest['is_core']);
    }

    public function test_provider_menu_items(): void
    {
        $provider = new ProfileServiceProvider($this->app);
        $items = $provider->getMenuItems();

        $this->assertCount(1, $items);
        $this->assertSame('profile.view', $items[0]['slug']);
        $this->assertSame('drawer', $items[0]['slot']);
        $this->assertSame('app', $items[0]['target']);
    }
}
