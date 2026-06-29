<?php

namespace Tests\Feature\Unit;

use App\Contracts\UserDataContributor;
use App\Models\Country;
use App\Models\Profile;
use App\Models\User;
use App\Models\UserSetting;
use App\Services\UserDataService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * UserDataService shapes the public (viewer-safe) and authenticated-self user
 * payloads. publicData() must omit private fields that aggregateUserData()
 * returns; profile gender/birthday are sourced from the USER columns;
 * online status follows the User::isOnline window.
 */
class UserDataServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): UserDataService
    {
        return app(UserDataService::class);
    }

    public function test_public_data_has_only_viewer_safe_keys(): void
    {
        $user = User::factory()->create(['bio' => 'hi']);

        $data = $this->service()->publicData($user);

        // Present (public).
        $this->assertSame($user->id, $data['id']);
        $this->assertSame($user->name, $data['name']);
        $this->assertSame($user->uuid, $data['uuid']);
        $this->assertSame('hi', $data['bio']);
        $this->assertArrayHasKey('is_online', $data);
        $this->assertArrayHasKey('stats', $data);
        $this->assertArrayHasKey('profile', $data);
        $this->assertArrayHasKey('roles', $data);

        // Private fields must NOT leak into the public payload.
        foreach (['email', 'phone', 'firebase_uuid', 'notification_id', 'settings', 'is_first'] as $private) {
            $this->assertArrayNotHasKey($private, $data, "public payload leaked [$private]");
        }
    }

    public function test_aggregate_data_includes_private_fields_and_settings(): void
    {
        $user = User::factory()->create();
        UserSetting::create(['user_id' => $user->id, 'key' => 'theme', 'value' => 'dark']);

        $data = $this->service()->aggregateUserData($user);

        $this->assertSame($user->email, $data['email']);
        $this->assertSame($user->phone, $data['phone']);
        $this->assertArrayHasKey('firebase_uuid', $data);
        $this->assertArrayHasKey('notification_id', $data);
        $this->assertSame(['theme' => 'dark'], $data['settings']);
        // is_first reflects is_points_first.
        $this->assertFalse($data['is_first']);
    }

    public function test_is_first_reflects_is_points_first_flag(): void
    {
        $user = User::factory()->create(['is_points_first' => true]);

        $this->assertTrue($this->service()->aggregateUserData($user)['is_first']);
    }

    public function test_null_profile_yields_array_with_null_gender_and_birthday(): void
    {
        $user = User::factory()->create(); // no Profile row, no user gender/birthday

        $profile = $this->service()->publicData($user)['profile'];

        $this->assertIsArray($profile);
        $this->assertNull($profile['gender']);
        $this->assertNull($profile['birthday']);
    }

    public function test_profile_gender_and_birthday_come_from_user_columns(): void
    {
        $user = User::factory()->create(['gender' => 1, 'birthday' => '1990-05-15']);
        // Profile relation carries DIFFERENT legacy values that must be overridden.
        Profile::create(['user_id' => $user->id, 'gender' => 2, 'birthday' => '2000-01-01']);

        $profile = $this->service()->publicData($user->fresh())['profile'];

        $this->assertSame(1, $profile['gender']);
        $this->assertSame('1990-05-15', $profile['birthday']);
    }

    public function test_profile_falls_back_to_profile_relation_when_user_columns_null(): void
    {
        $user = User::factory()->create(['gender' => null, 'birthday' => null]);
        Profile::create(['user_id' => $user->id, 'gender' => 2, 'birthday' => '1995-03-03']);

        $profile = $this->service()->publicData($user->fresh())['profile'];

        $this->assertSame(2, $profile['gender']);
        $this->assertSame('1995-03-03', $profile['birthday']);
    }

    public function test_is_online_true_when_recent_online_time(): void
    {
        $user = User::factory()->create(['online_time' => now()->subMinute()]);

        $data = $this->service()->publicData($user);

        $this->assertTrue($data['is_online']);
        $this->assertNotNull($data['last_seen']);
    }

    public function test_is_online_false_when_online_time_outside_window(): void
    {
        $user = User::factory()->create(['online_time' => now()->subHour()]);

        $this->assertFalse($this->service()->publicData($user)['is_online']);
    }

    public function test_is_online_false_and_last_seen_null_when_never_seen(): void
    {
        $user = User::factory()->create(['online_time' => null]);

        $data = $this->service()->publicData($user);

        $this->assertFalse($data['is_online']);
        $this->assertNull($data['last_seen']);
    }

    public function test_country_is_array_when_set_and_null_when_absent(): void
    {
        $country = Country::create(['name' => 'Egypt', 'e_name' => 'Egypt', 'iso' => 'EG']);
        $withCountry = User::factory()->create(['country_id' => $country->id]);
        $withoutCountry = User::factory()->create(['country_id' => null]);

        $this->assertIsArray($this->service()->publicData($withCountry)['country']);
        $this->assertSame('Egypt', $this->service()->publicData($withCountry)['country']['name']);
        $this->assertNull($this->service()->publicData($withoutCountry)['country']);
    }

    public function test_stats_default_to_zero_when_counters_absent(): void
    {
        $user = User::factory()->create();

        $stats = $this->service()->publicData($user)['stats'];

        $this->assertSame(['friends' => 0, 'following' => 0, 'followers' => 0], $stats);
    }

    public function test_roles_are_listed_by_key(): void
    {
        $user = User::factory()->create();
        $role = \App\Models\Role::create(['key' => 'vip', 'display_name' => 'VIP']);
        $user->roles()->attach($role->id);

        $this->assertSame(['vip'], $this->service()->publicData($user->fresh())['roles']);
    }

    public function test_registered_contributor_is_merged_into_aggregate_under_its_key(): void
    {
        $service = $this->service();
        $service->register(new class implements UserDataContributor {
            public function getKey(): string { return 'wallet'; }
            public function getUserData(User $user): ?array { return ['balance' => 100]; }
        });

        $data = $service->aggregateUserData(User::factory()->create());

        $this->assertSame(['balance' => 100], $data['wallet']);
    }

    public function test_contributor_returning_null_is_omitted(): void
    {
        $service = $this->service();
        $service->register(new class implements UserDataContributor {
            public function getKey(): string { return 'gifts'; }
            public function getUserData(User $user): ?array { return null; }
        });

        $data = $service->aggregateUserData(User::factory()->create());

        $this->assertArrayNotHasKey('gifts', $data);
    }
}
