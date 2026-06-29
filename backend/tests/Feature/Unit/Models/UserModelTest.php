<?php

namespace Tests\Feature;

use App\Models\Country;
use App\Models\Profile;
use App\Models\Role;
use App\Models\User;
use App\Models\UserSetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class UserModelTest extends TestCase
{
    use RefreshDatabase;

    // ---- casts -------------------------------------------------------------

    public function test_casts(): void
    {
        $user = User::factory()->create([
            'status' => 1, 'is_points_first' => 1, 'is_logout' => 0,
            'online_time' => now(),
        ]);
        $user->refresh();

        $this->assertIsBool($user->status);
        $this->assertIsBool($user->is_points_first);
        $this->assertIsBool($user->is_logout);
        $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $user->online_time);
        $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $user->email_verified_at);
    }

    public function test_password_and_remember_token_are_hidden(): void
    {
        $user = User::factory()->create();
        $array = $user->toArray();

        $this->assertArrayNotHasKey('password', $array);
        $this->assertArrayNotHasKey('remember_token', $array);
    }

    // ---- setPasswordAttribute (KNOWN double-hash footgun) ------------------

    public function test_password_mutator_bcrypts_plain_values(): void
    {
        $user = User::factory()->create(['password' => 'secret']);

        $this->assertTrue(Hash::check('secret', $user->password));
        $this->assertNotSame('secret', $user->password); // stored hashed
    }

    /**
     * BUG (KNOWN footgun): setPasswordAttribute ALWAYS bcrypts, so assigning an
     * already-hashed value double-hashes it — the original plain text no longer
     * verifies against the stored value. Documented in MEMORY; asserting current
     * behavior. User::setPasswordAttribute — User.php:62
     */
    public function test_password_mutator_double_hashes_an_already_hashed_value(): void
    {
        $alreadyHashed = bcrypt('secret');
        $user = User::factory()->create(['password' => $alreadyHashed]);

        // The plain text does NOT verify because the hash was hashed again.
        $this->assertFalse(Hash::check('secret', $user->password));
        // …and the stored value is not the hash we passed in either.
        $this->assertNotSame($alreadyHashed, $user->password);
    }

    public function test_password_mutator_ignores_empty_values(): void
    {
        $user = User::factory()->create(['password' => 'first']);
        $original = $user->password;

        // Assigning a falsy value leaves the existing hash untouched.
        $user->password = '';
        $user->save();

        $this->assertSame($original, $user->fresh()->password);
    }

    // ---- isOnline ----------------------------------------------------------

    public function test_is_online_false_when_never_seen(): void
    {
        $user = User::factory()->create(['online_time' => null]);
        $this->assertFalse($user->isOnline());
    }

    public function test_is_online_true_within_window(): void
    {
        $user = User::factory()->create(['online_time' => now()->subMinutes(2)]);
        $this->assertTrue($user->isOnline());
    }

    public function test_is_online_false_outside_window(): void
    {
        $user = User::factory()->create(['online_time' => now()->subMinutes(10)]);
        $this->assertFalse($user->isOnline());
    }

    public function test_is_online_respects_custom_window(): void
    {
        $user = User::factory()->create(['online_time' => now()->subMinutes(8)]);
        $this->assertFalse($user->isOnline());      // default 5 min window
        $this->assertTrue($user->isOnline(15));     // wider custom window
    }

    public function test_online_window_constant(): void
    {
        $this->assertSame(5, User::ONLINE_WINDOW_MINUTES);
    }

    // ---- uuid auto-generation (booted creating hook) ----------------------

    public function test_uuid_auto_generated_when_blank(): void
    {
        $user = User::create(['name' => 'No UUID', 'password' => 'x']);

        $this->assertNotNull($user->uuid);
        $this->assertMatchesRegularExpression('/^\d{7}$/', $user->uuid); // 7 digits
    }

    public function test_supplied_uuid_is_preserved(): void
    {
        $user = User::create(['name' => 'X', 'uuid' => 'admin-123', 'password' => 'x']);
        $this->assertSame('admin-123', $user->uuid);
    }

    // ---- relationships -----------------------------------------------------

    public function test_profile_relationship_and_avatar_accessor(): void
    {
        $user = User::factory()->create();
        Profile::create(['user_id' => $user->id, 'avatar' => 'avatars/a.png']);

        $this->assertInstanceOf(Profile::class, $user->profile);
        $this->assertSame('avatars/a.png', $user->avatar); // accessor → profile->avatar
    }

    public function test_avatar_accessor_null_without_profile(): void
    {
        $user = User::factory()->create();
        $this->assertNull($user->avatar);
    }

    public function test_country_relationship(): void
    {
        $country = Country::create(['name' => 'Egypt', 'e_name' => 'Egypt', 'phone_code' => '20']);
        $user = User::factory()->create(['country_id' => $country->id]);

        $this->assertInstanceOf(Country::class, $user->country);
        $this->assertSame('Egypt', $user->country->name);
    }

    public function test_roles_relationship_and_has_role(): void
    {
        $user = User::factory()->create();
        $admin = Role::create(['key' => 'admin', 'display_name' => 'Admin']);
        Role::create(['key' => 'vip', 'display_name' => 'VIP']);
        $user->roles()->attach($admin);

        $this->assertTrue($user->hasRole('admin'));
        $this->assertFalse($user->hasRole('vip'));
        $this->assertCount(1, $user->roles);
    }

    public function test_settings_relationship(): void
    {
        $user = User::factory()->create();
        UserSetting::create(['user_id' => $user->id, 'key' => 'lang', 'value' => 'en']);

        $this->assertCount(1, $user->settings);
        $this->assertSame('lang', $user->settings->first()->key);
    }

    // ---- soft deletes ------------------------------------------------------

    public function test_soft_deletes(): void
    {
        $user = User::factory()->create();
        $id = $user->id;
        $user->delete();

        $this->assertSoftDeleted('users', ['id' => $id]);
        $this->assertNull(User::find($id));
        $this->assertNotNull(User::withTrashed()->find($id));
    }
}
