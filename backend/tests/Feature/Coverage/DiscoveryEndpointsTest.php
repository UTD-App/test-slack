<?php

namespace Tests\Feature\Coverage;

use App\Models\Config;
use App\Models\Language;
use App\Models\Page;
use App\Models\StacScreen;
use App\Models\TranslationKey;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Endpoint coverage — the public discovery / server-driven-UI / UTD-Studio
 * surface that had no test:
 *   GET /packages/installed, POST /packages/register,
 *   GET /menu, GET /menu/version, GET /page/{key},
 *   GET /stac/{name}, GET /stac/{name}/version, GET /stac/packages, GET /stac/screens,
 *   GET /utd/manifest, GET|POST /utd/translations, GET /utd/packages/{key}/sample.
 *
 * Auth model under test:
 *   utd.secret  — allows when no `utd_secret` config is set (dev mode), else 401.
 *   stac.auth   — requires a configured `utd_stac_key` + matching X-Stac-Key.
 */
class DiscoveryEndpointsTest extends TestCase
{
    use RefreshDatabase;

    // ── packages/installed ───────────────────────────────────────────────────
    public function test_packages_installed_always_includes_base(): void
    {
        $this->getJson('/api/packages/installed')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['data' => ['packages', 'server', 'capabilities' => ['wallet']]])
            ->assertJsonFragment(['packages' => ['base']]);
    }

    // ── packages/register (utd.secret; dev mode allows) ───────────────────────
    public function test_packages_register_adds_translation_keys(): void
    {
        $this->postJson('/api/packages/register', [
            'package' => 'demo-pkg',
            'version' => '1.0.0',
            'keys'    => [['key' => 'demo.title', 'group' => 'demo']],
        ])->assertStatus(200)->assertJsonPath('data.keys_added', 1);

        $this->assertDatabaseHas('translation_keys', ['key' => 'demo.title', 'group' => 'demo']);
    }

    public function test_packages_register_blocked_when_secret_configured(): void
    {
        Config::create(['name' => 'utd_secret', 'value' => 's3cr3t']);

        $this->postJson('/api/packages/register', ['package' => 'x', 'version' => '1'])
            ->assertStatus(401);
    }

    // ── menu ───────────────────────────────────────────────────────────────
    public function test_menu_version_is_public(): void
    {
        $this->getJson('/api/menu/version')
            ->assertStatus(200)
            ->assertJsonStructure(['data' => ['version']]);
    }

    public function test_menu_index_returns_items(): void
    {
        $this->getJson('/api/menu')
            ->assertStatus(200)
            ->assertJsonStructure(['data' => ['version', 'items']]);
    }

    // ── page/{key} ───────────────────────────────────────────────────────────
    public function test_page_returns_localized_content(): void
    {
        Page::create([
            'key'   => 'privacy-policy',
            'title' => ['en' => 'Privacy', 'ar' => 'الخصوصية'],
            'body'  => ['en' => 'Body EN', 'ar' => 'المحتوى'],
        ]);

        $this->withHeader('X-localization', 'en')
            ->getJson('/api/page/privacy-policy')
            ->assertStatus(200)
            ->assertJsonPath('data.title', 'Privacy')
            ->assertJsonPath('data.body', 'Body EN');
    }

    public function test_missing_page_is_404(): void
    {
        $this->getJson('/api/page/nope')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    // ── stac single screen ─────────────────────────────────────────────────
    public function test_stac_show_returns_screen(): void
    {
        StacScreen::create([
            'name' => 'home', 'package' => 'base', 'version' => '3',
            'content' => ['type' => 'Scaffold'], 'is_active' => true,
        ]);

        $this->getJson('/api/stac/home')
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'home')
            ->assertJsonPath('data.version', '3');
    }

    public function test_stac_version_returns_version_only(): void
    {
        StacScreen::create([
            'name' => 'login', 'package' => 'base', 'version' => '7',
            'content' => ['type' => 'Scaffold'], 'is_active' => true,
        ]);

        $this->getJson('/api/stac/login/version')
            ->assertStatus(200)
            ->assertJsonPath('data.version', '7');
    }

    public function test_stac_show_missing_is_404(): void
    {
        $this->getJson('/api/stac/ghost')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    // ── stac/packages (dev mode) ───────────────────────────────────────────
    public function test_stac_packages_lists_base(): void
    {
        $this->getJson('/api/stac/packages')
            ->assertStatus(200)
            ->assertJsonFragment(['slug' => 'base']);
    }

    // ── stac/screens (stac.auth) ───────────────────────────────────────────
    public function test_stac_screens_requires_key(): void
    {
        Config::create(['name' => 'utd_stac_key', 'value' => 'k-123']);

        $this->getJson('/api/stac/screens')->assertStatus(401);

        StacScreen::create([
            'name' => 'feed', 'package' => 'base', 'version' => '1',
            'content' => ['type' => 'Scaffold'], 'is_active' => true,
        ]);

        $this->withHeader('X-Stac-Key', 'k-123')
            ->getJson('/api/stac/screens')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonFragment(['name' => 'feed']);
    }

    // ── utd/manifest (utd.secret) ──────────────────────────────────────────
    public function test_utd_manifest_dev_mode_returns_payload(): void
    {
        $this->getJson('/api/utd/manifest')
            ->assertStatus(200)
            ->assertJsonStructure(['version', 'app' => ['name', 'locales'], 'packages']);
    }

    public function test_utd_manifest_blocked_with_wrong_secret(): void
    {
        Config::create(['name' => 'utd_secret', 'value' => 'right']);

        $this->withHeader('X-UTD-Secret', 'wrong')
            ->getJson('/api/utd/manifest')->assertStatus(401);

        $this->withHeader('X-UTD-Secret', 'right')
            ->getJson('/api/utd/manifest')->assertStatus(200);
    }

    // ── utd/translations pull + write-back ─────────────────────────────────
    public function test_utd_translations_pull_returns_catalog(): void
    {
        Language::create(['code' => 'en', 'name' => 'English', 'native_name' => 'English', 'is_rtl' => false, 'is_active' => true, 'is_default' => true]);

        $this->getJson('/api/utd/translations')
            ->assertStatus(200)
            ->assertJsonStructure(['version', 'default_locale', 'locales', 'translations']);
    }

    public function test_utd_translations_writeback_persists_to_db(): void
    {
        Language::create(['code' => 'en', 'name' => 'English', 'native_name' => 'English', 'is_rtl' => false, 'is_active' => true, 'is_default' => true]);

        $this->postJson('/api/utd/translations', [
            'translations' => ['en' => ['demo.hello' => 'Hello World']],
        ])->assertStatus(200)->assertJsonPath('status', true);

        $this->assertDatabaseHas('translation_keys', ['key' => 'demo.hello']);
        $this->assertDatabaseHas('translations', ['value' => 'Hello World']);
    }

    // ── utd/packages/{key}/sample ──────────────────────────────────────────
    public function test_utd_sample_unknown_key_is_404(): void
    {
        $this->getJson('/api/utd/packages/does-not-exist/sample')
            ->assertStatus(404)
            ->assertJsonPath('error', 'not_found');
    }
}
