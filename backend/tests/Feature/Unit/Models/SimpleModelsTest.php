<?php

namespace Tests\Feature;

use App\Models\Code;
use App\Models\Country;
use App\Models\DevicesTokenHistory;
use App\Models\Language;
use App\Models\NotificationPreference;
use App\Models\Role;
use App\Models\Setting;
use App\Models\StacScreen;
use App\Models\Translation;
use App\Models\TranslationKey;
use App\Models\User;
use App\Support\AppLanguages;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Casts / relationships / config flags for the smaller models that don't warrant
 * a dedicated file.
 */
class SimpleModelsTest extends TestCase
{
    use RefreshDatabase;

    // ---- Country -----------------------------------------------------------

    public function test_country_has_no_timestamps(): void
    {
        $this->assertFalse((new Country())->usesTimestamps());

        $c = Country::create(['name' => 'Egypt', 'e_name' => 'Egypt', 'phone_code' => '20']);
        $this->assertArrayNotHasKey('created_at', $c->getAttributes());
    }

    public function test_country_fillable(): void
    {
        $c = Country::create([
            'name' => 'مصر', 'e_name' => 'Egypt', 'flag' => 'eg.png',
            'language' => 'ar', 'phone_code' => '20', 'iso' => 'EG',
            'iso_numeric' => '818', 'currency_numeric' => '818',
        ]);
        $this->assertSame('Egypt', $c->e_name);
        $this->assertSame('EG', $c->iso);
    }

    // ---- StacScreen --------------------------------------------------------

    public function test_stac_screen_casts(): void
    {
        $s = StacScreen::create([
            'name' => 'home', 'content' => ['type' => 'column'], 'is_active' => 1,
        ]);
        $s->refresh();

        $this->assertSame(['type' => 'column'], $s->content);
        $this->assertIsBool($s->is_active);
        $this->assertTrue($s->is_active);
    }

    public function test_stac_screen_defaults(): void
    {
        $s = StacScreen::create(['name' => 'gift', 'content' => []]);
        $s->refresh();
        $this->assertSame('base', $s->package); // default from migration
        $this->assertSame('1', (string) $s->version);
    }

    // ---- Setting -----------------------------------------------------------

    public function test_setting_fillable(): void
    {
        $s = Setting::create(['key' => 'site_name', 'value' => 'Eagle']);
        $this->assertSame('Eagle', Setting::where('key', 'site_name')->value('value'));
        $this->assertSame('Eagle', $s->value);
    }

    // ---- Code --------------------------------------------------------------

    public function test_code_is_unguarded(): void
    {
        $c = Code::create(['phone' => '+201000000000', 'code' => '123456']);
        $this->assertSame('codes', $c->getTable());
        $this->assertDatabaseHas('codes', ['phone' => '+201000000000', 'code' => '123456']);
    }

    // ---- DevicesTokenHistory ----------------------------------------------

    public function test_devices_token_history_is_unguarded(): void
    {
        $d = DevicesTokenHistory::create(['device_token' => 'tok-1', 'count' => 3]);
        $this->assertDatabaseHas('devices_token_histories', ['device_token' => 'tok-1', 'count' => 3]);
        $this->assertSame('tok-1', $d->device_token);
    }

    // ---- NotificationPreference -------------------------------------------

    public function test_notification_preference_enabled_cast(): void
    {
        $p = NotificationPreference::create([
            'user_id' => 1, 'category' => 'social', 'channel' => 'push', 'enabled' => 0,
        ]);
        $this->assertIsBool($p->refresh()->enabled);
        $this->assertFalse($p->enabled);
    }

    public function test_notification_preference_nullable_channel(): void
    {
        $p = NotificationPreference::create([
            'user_id' => 1, 'category' => 'finance', 'channel' => null,
        ]);
        $this->assertNull($p->channel);
        $this->assertTrue($p->refresh()->enabled); // defaults true
    }

    // ---- TranslationKey / Translation -------------------------------------

    public function test_translation_key_translations_relationship(): void
    {
        AppLanguages::flush();
        $lang = Language::create([
            'code' => 'en', 'name' => 'English', 'native_name' => 'English',
            'is_rtl' => false, 'is_active' => true, 'is_default' => true,
        ]);
        $key = TranslationKey::create(['key' => 'home.welcome', 'group' => 'home']);
        Translation::create([
            'language_id' => $lang->id, 'translation_key_id' => $key->id, 'value' => 'Welcome',
        ]);

        $this->assertCount(1, $key->translations);
    }

    public function test_translation_belongs_to_language_and_key(): void
    {
        AppLanguages::flush();
        $lang = Language::create([
            'code' => 'en', 'name' => 'English', 'native_name' => 'English',
            'is_rtl' => false, 'is_active' => true, 'is_default' => true,
        ]);
        $key = TranslationKey::create(['key' => 'a.b', 'group' => 'a']);
        $t = Translation::create([
            'language_id' => $lang->id, 'translation_key_id' => $key->id, 'value' => 'V',
        ]);

        $this->assertTrue($t->language->is($lang));
        $this->assertTrue($t->key->is($key));   // custom FK translation_key_id
    }

    // ---- Role --------------------------------------------------------------

    public function test_role_users_relationship(): void
    {
        $role = Role::create(['key' => 'vip', 'display_name' => 'VIP']);
        $user = User::factory()->create();
        $role->users()->attach($user);

        $this->assertCount(1, $role->users);
        $this->assertTrue($role->users->first()->is($user));
    }
}
