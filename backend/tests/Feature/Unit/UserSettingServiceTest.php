<?php

namespace Tests\Feature\Unit;

use App\Models\User;
use App\Models\UserSetting;
use App\Services\UserSettingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * UserSettingService: per-user key/value store with JSON encode/decode,
 * defaults, overwrite, bulk write, and getAll aggregation.
 */
class UserSettingServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): UserSettingService
    {
        return app(UserSettingService::class);
    }

    public function test_get_returns_default_when_missing(): void
    {
        $user = User::factory()->create();

        $this->assertSame('fallback', $this->service()->get($user, 'theme', 'fallback'));
        $this->assertNull($this->service()->get($user, 'missing'));
    }

    public function test_set_and_get_roundtrips_a_scalar_string(): void
    {
        $user = User::factory()->create();
        $service = $this->service();

        $service->set($user, 'theme', 'dark');

        $this->assertSame('dark', $service->get($user, 'theme'));
    }

    public function test_set_encodes_and_get_decodes_arrays(): void
    {
        $user = User::factory()->create();
        $service = $this->service();

        $service->set($user, 'prefs', ['a' => 1, 'b' => [2, 3]]);

        $this->assertSame(['a' => 1, 'b' => [2, 3]], $service->get($user, 'prefs'));
    }

    public function test_set_encodes_and_get_decodes_booleans_and_ints(): void
    {
        $user = User::factory()->create();
        $service = $this->service();

        $service->set($user, 'push', true);
        $service->set($user, 'count', 7);

        $this->assertTrue($service->get($user, 'push'));
        $this->assertSame(7, $service->get($user, 'count'));
    }

    public function test_set_overwrites_existing_value(): void
    {
        $user = User::factory()->create();
        $service = $this->service();

        $service->set($user, 'lang', 'en');
        $service->set($user, 'lang', 'ar');

        $this->assertSame('ar', $service->get($user, 'lang'));
        $this->assertDatabaseCount('user_settings', 1);
    }

    public function test_get_all_returns_decoded_map(): void
    {
        $user = User::factory()->create();
        $service = $this->service();

        $service->set($user, 'theme', 'dark');
        $service->set($user, 'prefs', ['x' => 1]);

        $all = $service->getAll($user);

        $this->assertSame('dark', $all['theme']);
        $this->assertSame(['x' => 1], $all['prefs']);
    }

    public function test_get_all_is_empty_for_user_with_no_settings(): void
    {
        $this->assertSame([], $this->service()->getAll(User::factory()->create()));
    }

    public function test_get_all_scopes_to_the_user(): void
    {
        $a = User::factory()->create();
        $b = User::factory()->create();
        $service = $this->service();

        $service->set($a, 'theme', 'dark');
        $service->set($b, 'theme', 'light');

        $this->assertSame(['theme' => 'dark'], $service->getAll($a));
        $this->assertSame(['theme' => 'light'], $service->getAll($b));
    }

    public function test_set_bulk_writes_every_key(): void
    {
        $user = User::factory()->create();
        $service = $this->service();

        $service->setBulk($user, [
            'theme' => 'dark',
            'lang' => 'ar',
            'notifications' => ['push' => true],
        ]);

        $all = $service->getAll($user);
        $this->assertSame('dark', $all['theme']);
        $this->assertSame('ar', $all['lang']);
        $this->assertSame(['push' => true], $all['notifications']);
        $this->assertDatabaseCount('user_settings', 3);
    }

    public function test_set_bulk_overwrites_existing_and_adds_new(): void
    {
        $user = User::factory()->create();
        $service = $this->service();

        $service->set($user, 'theme', 'light');
        $service->setBulk($user, ['theme' => 'dark', 'lang' => 'en']);

        // Key order is unspecified (DB pluck), so compare order-independently.
        $this->assertEqualsCanonicalizing(['theme' => 'dark', 'lang' => 'en'], $service->getAll($user));
    }

    public function test_explicit_null_value_roundtrips(): void
    {
        $user = User::factory()->create();
        $service = $this->service();

        // json_encode(null) === 'null'; the decode guard treats 'null' as null, not the literal string.
        $service->set($user, 'maybe', null);

        $this->assertNull($service->get($user, 'maybe'));
        $this->assertSame('null', UserSetting::where('user_id', $user->id)->where('key', 'maybe')->value('value'));
    }
}
