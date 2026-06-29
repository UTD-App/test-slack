<?php

namespace Tests\Feature\Unit;

use App\Contracts\MenuContributor;
use App\Models\Config;
use App\Models\MenuItem;
use App\Models\Package;
use App\Services\MenuService;
use App\Services\PackageRegistry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

/**
 * MenuService: idempotent seeding of contributed defaults, enabled-package +
 * app-target filtered/ordered payload, and the versioned cache.
 */
class MenuServiceTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Fresh instance so the base provider's already-registered menu contributors
     * don't seed extra rows into our isolation cases. PackageRegistry (used only
     * by buildAppPayload) is the real container singleton.
     */
    private function service(): MenuService
    {
        return new MenuService(app(PackageRegistry::class));
    }

    private function contributor(string $package, array $items): MenuContributor
    {
        return new class($package, $items) implements MenuContributor {
            public function __construct(private string $package, private array $items) {}
            public function getPackage(): string { return $this->package; }
            public function getMenuItems(): array { return $this->items; }
        };
    }

    public function test_sync_defaults_inserts_missing_rows_and_returns_count(): void
    {
        $service = $this->service();
        $service->register($this->contributor('base', [
            ['slug' => 'home', 'label_key' => 'menu.home', 'slot' => 'home', 'order' => 1],
            ['slug' => 'me', 'label_key' => 'menu.me', 'slot' => 'home', 'order' => 2],
        ]));

        $created = $service->syncDefaults();

        $this->assertSame(2, $created);
        $this->assertDatabaseHas('menu_items', ['slug' => 'home', 'package' => 'base']);
        $this->assertDatabaseHas('menu_items', ['slug' => 'me']);
    }

    public function test_sync_defaults_is_idempotent_and_preserves_admin_edits(): void
    {
        $service = $this->service();
        $service->register($this->contributor('base', [
            ['slug' => 'home', 'label_key' => 'menu.home', 'slot' => 'home', 'order' => 1],
        ]));

        $service->syncDefaults();
        // Admin renames the label.
        MenuItem::where('slug', 'home')->update(['label_key' => 'custom.label']);

        $secondRun = $service->syncDefaults();

        $this->assertSame(0, $secondRun, 'existing slug should not be recreated');
        $this->assertSame('custom.label', MenuItem::where('slug', 'home')->value('label_key'));
    }

    public function test_sync_defaults_skips_rows_without_slug(): void
    {
        $service = $this->service();
        $service->register($this->contributor('base', [
            ['label_key' => 'no.slug'],
            ['slug' => '', 'label_key' => 'empty.slug'],
            ['slug' => 'valid', 'label_key' => 'menu.valid'],
        ]));

        $created = $service->syncDefaults();

        $this->assertSame(1, $created);
        $this->assertDatabaseCount('menu_items', 1);
    }

    public function test_build_payload_excludes_disabled_packages(): void
    {
        Package::create(['slug' => 'gifts', 'name' => 'Gifts', 'enabled' => false]);
        app(\App\Services\PackageRegistry::class)->forgetCache();

        MenuItem::create(['slug' => 'home', 'package' => 'base', 'label_key' => 'menu.home', 'slot' => 'home', 'order' => 1, 'target' => 'app', 'is_visible' => true]);
        MenuItem::create(['slug' => 'gifts', 'package' => 'gifts', 'label_key' => 'menu.gifts', 'slot' => 'home', 'order' => 2, 'target' => 'app', 'is_visible' => true]);

        $payload = $this->service()->buildAppPayload();
        $slugs = array_column($payload, 'slug');

        $this->assertContains('home', $slugs);
        $this->assertNotContains('gifts', $slugs, 'disabled-package menu item must be excluded');
    }

    public function test_build_payload_excludes_admin_only_target(): void
    {
        MenuItem::create(['slug' => 'home', 'package' => 'base', 'label_key' => 'menu.home', 'slot' => 'home', 'order' => 1, 'target' => 'app', 'is_visible' => true]);
        MenuItem::create(['slug' => 'both', 'package' => 'base', 'label_key' => 'menu.both', 'slot' => 'home', 'order' => 2, 'target' => 'both', 'is_visible' => true]);
        MenuItem::create(['slug' => 'adminonly', 'package' => 'base', 'label_key' => 'menu.admin', 'slot' => 'home', 'order' => 3, 'target' => 'admin', 'is_visible' => true]);

        $slugs = array_column($this->service()->buildAppPayload(), 'slug');

        $this->assertContains('home', $slugs);
        $this->assertContains('both', $slugs);
        $this->assertNotContains('adminonly', $slugs);
    }

    public function test_build_payload_orders_by_slot_then_order(): void
    {
        MenuItem::create(['slug' => 'b', 'package' => 'base', 'label_key' => 'x', 'slot' => 'home', 'order' => 5, 'target' => 'app', 'is_visible' => true]);
        MenuItem::create(['slug' => 'a', 'package' => 'base', 'label_key' => 'x', 'slot' => 'home', 'order' => 1, 'target' => 'app', 'is_visible' => true]);
        MenuItem::create(['slug' => 'z', 'package' => 'base', 'label_key' => 'x', 'slot' => 'drawer', 'order' => 1, 'target' => 'app', 'is_visible' => true]);

        $slugs = array_column($this->service()->buildAppPayload(), 'slug');

        // slot 'drawer' < 'home' alphabetically; within home, order 1 before 5.
        $this->assertSame(['z', 'a', 'b'], $slugs);
    }

    public function test_version_defaults_to_zero_and_is_cached(): void
    {
        Cache::flush();
        $this->assertSame('0', $this->service()->version());
    }

    public function test_bump_version_increments_persists_and_busts_cache(): void
    {
        $service = $this->service();
        $service->version(); // warm cache to '0'

        $service->bumpVersion();

        $stored = Config::where('name', MenuService::VERSION_KEY)->value('value');
        $this->assertNotNull($stored);
        $this->assertGreaterThan(0, (int) $stored);
        // Cache was busted: version() reflects the new persisted value.
        $this->assertSame($stored, $service->version());
    }

    public function test_sync_defaults_bumps_version_when_rows_created(): void
    {
        $service = $this->service();
        $service->register($this->contributor('base', [
            ['slug' => 'home', 'label_key' => 'menu.home', 'slot' => 'home'],
        ]));

        $before = $service->version();
        $service->syncDefaults();

        $this->assertNotSame($before, $service->version());
    }
}
