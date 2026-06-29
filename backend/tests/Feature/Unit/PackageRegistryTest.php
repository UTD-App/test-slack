<?php

namespace Tests\Feature\Unit;

use App\Models\Package;
use App\Services\PackageRegistry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

/**
 * PackageRegistry: in-memory manifest registration, DB sync (admin columns
 * preserved), and the enabled/disabled semantics — base is always enabled,
 * absent rows fail open, explicit enabled=false disables. Results are cached.
 */
class PackageRegistryTest extends TestCase
{
    use RefreshDatabase;

    private function registry(): PackageRegistry
    {
        // Fresh instance per test so in-memory manifests don't leak.
        return new PackageRegistry();
    }

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

    public function test_base_is_always_enabled(): void
    {
        $this->assertTrue($this->registry()->isEnabled('base'));
    }

    public function test_base_enabled_even_when_row_marks_it_disabled(): void
    {
        Package::create(['slug' => 'base', 'name' => 'Base', 'enabled' => false]);

        $this->assertTrue($this->registry()->isEnabled('base'), 'base is hard-coded enabled');
    }

    public function test_unknown_package_is_enabled_fail_open(): void
    {
        // No row at all → treated as enabled (pre-sync drop-in module).
        $this->assertTrue($this->registry()->isEnabled('brand-new'));
    }

    public function test_enabled_row_is_enabled(): void
    {
        Package::create(['slug' => 'gifts', 'name' => 'Gifts', 'enabled' => true]);

        $this->assertTrue($this->registry()->isEnabled('gifts'));
    }

    public function test_disabled_row_is_not_enabled(): void
    {
        Package::create(['slug' => 'gifts', 'name' => 'Gifts', 'enabled' => false]);

        $this->assertFalse($this->registry()->isEnabled('gifts'));
    }

    public function test_enabled_slugs_always_includes_base(): void
    {
        $this->assertContains('base', $this->registry()->enabledSlugs());
    }

    public function test_enabled_slugs_lists_enabled_rows_plus_base_uniquely(): void
    {
        Package::create(['slug' => 'gifts', 'name' => 'Gifts', 'enabled' => true]);
        Package::create(['slug' => 'moment', 'name' => 'Moment', 'enabled' => false]);
        Package::create(['slug' => 'base', 'name' => 'Base', 'enabled' => true]);

        $slugs = $this->registry()->enabledSlugs();

        $this->assertContains('gifts', $slugs);
        $this->assertContains('base', $slugs);
        $this->assertNotContains('moment', $slugs);
        // base appears exactly once even though it also has an enabled row.
        $this->assertSame(1, array_count_values($slugs)['base']);
    }

    public function test_disabled_slugs_lists_only_disabled_rows(): void
    {
        Package::create(['slug' => 'gifts', 'name' => 'Gifts', 'enabled' => true]);
        Package::create(['slug' => 'moment', 'name' => 'Moment', 'enabled' => false]);

        $disabled = $this->registry()->disabledSlugs();

        $this->assertSame(['moment'], $disabled);
    }

    public function test_register_stores_manifest_by_slug_and_ignores_empty_slug(): void
    {
        $registry = $this->registry();
        $registry->register(['slug' => 'gifts', 'name' => 'Gifts']);
        $registry->register(['slug' => '']); // ignored
        $registry->register(['name' => 'No slug']); // ignored

        $all = $registry->all();
        $this->assertArrayHasKey('gifts', $all);
        $this->assertCount(1, $all);
    }

    public function test_sync_to_database_inserts_rows_with_defaults(): void
    {
        $registry = $this->registry();
        $registry->register(['slug' => 'gifts']); // no name/version → derived defaults

        $count = $registry->syncToDatabase();

        $this->assertSame(1, $count);
        $row = Package::where('slug', 'gifts')->firstOrFail();
        $this->assertSame('Gifts', $row->name); // ucwords from slug
        $this->assertSame('1.0.0', $row->version);
        $this->assertTrue($row->enabled); // column default
        $this->assertNotNull($row->installed_at);
    }

    public function test_sync_preserves_admin_enabled_and_order_on_existing_rows(): void
    {
        Package::create(['slug' => 'gifts', 'name' => 'Old Name', 'enabled' => false, 'order' => 9]);

        $registry = $this->registry();
        $registry->register(['slug' => 'gifts', 'name' => 'New Name', 'version' => '2.0.0']);
        $registry->syncToDatabase();

        $row = Package::where('slug', 'gifts')->firstOrFail();
        $this->assertSame('New Name', $row->name); // manifest fields updated
        $this->assertSame('2.0.0', $row->version);
        $this->assertFalse($row->enabled); // admin column untouched
        $this->assertSame(9, $row->order);  // admin column untouched
    }

    public function test_sync_does_not_clobber_installed_at_on_resync(): void
    {
        $registry = $this->registry();
        $registry->register(['slug' => 'gifts']);
        $registry->syncToDatabase();
        $first = Package::where('slug', 'gifts')->value('installed_at');

        // Re-sync the same package.
        $registry2 = $this->registry();
        $registry2->register(['slug' => 'gifts', 'version' => '2.0.0']);
        $registry2->syncToDatabase();

        $this->assertEquals(
            (string) $first,
            (string) Package::where('slug', 'gifts')->value('installed_at'),
        );
    }

    public function test_results_are_cached_until_forget(): void
    {
        $registry = $this->registry();
        $this->assertSame(['base'], $registry->enabledSlugs()); // warms cache (no rows)

        // Insert a row directly with the query builder so the model's saved()
        // cache-buster doesn't fire — proving the value is genuinely cached.
        \DB::table('packages')->insert([
            'slug' => 'gifts', 'name' => 'Gifts', 'enabled' => true,
            'created_at' => now(), 'updated_at' => now(),
        ]);

        $this->assertSame(['base'], $registry->enabledSlugs(), 'stale cache returns base only');

        $registry->forgetCache();
        $this->assertContains('gifts', $registry->enabledSlugs());
    }
}
