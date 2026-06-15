<?php

namespace Tests\Feature;

use App\Models\Config;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Covers the public launch gate GET /api/app-version: force-update, maintenance,
 * branding and color blocks — every decision branch + defaults.
 */
class AppVersionApiTest extends TestCase
{
    use RefreshDatabase;

    private function set(string $key, string $value): void
    {
        Config::create(['name' => $key, 'value' => $value]);
    }

    private function hit(string $platform = 'android', int $version = 5)
    {
        return $this->getJson("/api/app-version?platform={$platform}&version={$version}");
    }

    public function test_no_config_means_no_gate_and_null_theme(): void
    {
        $this->hit()
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.force_update', false)
            ->assertJsonPath('data.update_available', false)
            ->assertJsonPath('data.maintenance', false)
            ->assertJsonPath('data.store_url', null)
            ->assertJsonPath('data.theme.primary', null)
            ->assertJsonPath('data.theme.bg_gradient_1', null)
            ->assertJsonPath('data.app.name', config('app.name'));
    }

    public function test_force_update_when_below_min_version(): void
    {
        $this->set('android_min_version', '50');

        $this->hit(version: 10)
            ->assertJsonPath('data.force_update', true);
    }

    public function test_force_update_when_required_and_behind_latest(): void
    {
        $this->set('android_latest_version', '60');
        $this->set('android_update_required', '1');

        $this->hit(version: 55)
            ->assertJsonPath('data.force_update', true)
            ->assertJsonPath('data.update_available', true);
    }

    public function test_no_force_at_latest_version(): void
    {
        $this->set('android_latest_version', '60');
        $this->set('android_update_required', '1');

        $this->hit(version: 60)
            ->assertJsonPath('data.force_update', false)
            ->assertJsonPath('data.update_available', false);
    }

    public function test_optional_update_available_without_force(): void
    {
        // latest set but update NOT required → soft update only.
        $this->set('android_latest_version', '60');

        $this->hit(version: 55)
            ->assertJsonPath('data.force_update', false)
            ->assertJsonPath('data.update_available', true);
    }

    public function test_unknown_version_never_forces(): void
    {
        $this->set('android_min_version', '50');

        // version 0 = client didn't report → never lock out.
        $this->hit(version: 0)
            ->assertJsonPath('data.force_update', false);
    }

    public function test_maintenance_mode_with_message(): void
    {
        $this->set('maintenance_mode', '1');
        $this->set('maintenance_message', 'Back soon');

        $this->hit()
            ->assertJsonPath('data.maintenance', true)
            ->assertJsonPath('data.maintenance_message', 'Back soon');
    }

    public function test_per_platform_thresholds_are_isolated(): void
    {
        $this->set('ios_min_version', '100');

        // iOS client below the iOS floor is forced…
        $this->hit(platform: 'ios', version: 50)
            ->assertJsonPath('data.platform', 'ios')
            ->assertJsonPath('data.force_update', true);

        // …but Android (no android floor) is not.
        $this->hit(platform: 'android', version: 50)
            ->assertJsonPath('data.force_update', false);
    }

    public function test_invalid_platform_falls_back_to_android(): void
    {
        $this->set('android_min_version', '50');

        $this->hit(platform: 'windows', version: 10)
            ->assertJsonPath('data.platform', 'android')
            ->assertJsonPath('data.force_update', true);
    }

    public function test_store_url_is_returned(): void
    {
        $this->set('android_store_url', 'https://play.google.com/x');

        $this->hit()
            ->assertJsonPath('data.store_url', 'https://play.google.com/x');
    }

    public function test_branding_block_reflects_config(): void
    {
        $this->set('app_name', 'UTD Live');
        $this->set('support_email', 'help@utd.app');
        $this->set('privacy_url', 'https://utd.app/privacy');

        $this->hit()
            ->assertJsonPath('data.app.name', 'UTD Live')
            ->assertJsonPath('data.app.support_email', 'help@utd.app')
            ->assertJsonPath('data.app.privacy_url', 'https://utd.app/privacy')
            ->assertJsonPath('data.app.terms_url', null);
    }

    public function test_theme_override_returns_value_else_null(): void
    {
        $this->set('theme_primary', '#FF0000');

        $this->hit()
            ->assertJsonPath('data.theme.primary', '#FF0000')
            ->assertJsonPath('data.theme.accent', null);
    }
}
