<?php

namespace Tests\Feature;

use App\Models\Package;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PackageModelTest extends TestCase
{
    use RefreshDatabase;

    private function make(array $overrides = []): Package
    {
        return Package::create(array_merge([
            'slug' => 'audio-room', 'name' => 'Audio Room',
        ], $overrides));
    }

    public function test_casts(): void
    {
        $p = $this->make([
            'enabled'      => 1,
            'is_core'      => 0,
            'dependencies' => ['wallet', 'social'],
            'meta'         => ['cap' => true],
            'installed_at' => now(),
        ]);
        $p->refresh();

        $this->assertIsBool($p->enabled);
        $this->assertIsBool($p->is_core);
        $this->assertSame(['wallet', 'social'], $p->dependencies);
        $this->assertSame(['cap' => true], $p->meta);
        $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $p->installed_at);
    }

    public function test_enabled_defaults_true_and_is_core_defaults_false(): void
    {
        $p = $this->make();
        $p->refresh();
        $this->assertTrue($p->enabled);
        $this->assertFalse($p->is_core);
    }

    public function test_save_and_delete_do_not_error_with_registry_cache_forget(): void
    {
        // The booted() hook calls PackageRegistry::forgetCache() on save/delete.
        // Just assert these lifecycle events succeed end to end.
        $p = $this->make();
        $p->update(['enabled' => false]);
        $this->assertFalse($p->fresh()->enabled);

        $p->delete();
        $this->assertDatabaseMissing('packages', ['slug' => 'audio-room']);
    }

    public function test_nullable_json_columns_default_null(): void
    {
        $p = $this->make();
        $p->refresh();
        $this->assertNull($p->dependencies);
        $this->assertNull($p->meta);
    }
}
