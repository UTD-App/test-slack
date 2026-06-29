<?php

namespace Tests\Feature;

use App\Models\Config;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class ConfigModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_is_hidden_is_cast_to_boolean(): void
    {
        $c = Config::create(['name' => 'secret_key', 'value' => 'x', 'is_hidden' => 1]);
        $this->assertIsBool($c->refresh()->is_hidden);
        $this->assertTrue($c->is_hidden);
    }

    public function test_map_returns_name_to_value_pairs(): void
    {
        Config::create(['name' => 'app_name', 'value' => 'Eagle']);
        Config::create(['name' => 'version', 'value' => '1.0']);

        $map = Config::map();
        $this->assertSame('Eagle', $map['app_name']);
        $this->assertSame('1.0', $map['version']);
    }

    public function test_map_is_cached(): void
    {
        Config::create(['name' => 'app_name', 'value' => 'Eagle']);
        $this->assertSame('Eagle', Config::map()['app_name']);

        // The cache key exists after the first read.
        $this->assertTrue(Cache::has(Config::MAP_CACHE_KEY));
    }

    public function test_saving_a_config_invalidates_the_cached_map(): void
    {
        Config::create(['name' => 'app_name', 'value' => 'Eagle']);
        $this->assertSame('Eagle', Config::map()['app_name']); // warm cache

        // A new row's saved() event flushes the map; next read rebuilds.
        Config::create(['name' => 'tagline', 'value' => 'Fly']);
        $this->assertArrayHasKey('tagline', Config::map());
    }

    public function test_updating_a_config_invalidates_the_cached_map(): void
    {
        $c = Config::create(['name' => 'app_name', 'value' => 'Old']);
        $this->assertSame('Old', Config::map()['app_name']); // warm cache

        $c->update(['value' => 'New']);
        $this->assertSame('New', Config::map()['app_name']);
    }

    public function test_deleting_a_config_invalidates_the_cached_map(): void
    {
        $c = Config::create(['name' => 'temp', 'value' => '1']);
        $this->assertArrayHasKey('temp', Config::map()); // warm cache

        $c->delete();
        $this->assertArrayNotHasKey('temp', Config::map());
    }

    public function test_flush_map_cache_forgets_the_key(): void
    {
        Config::create(['name' => 'x', 'value' => '1']);
        Config::map(); // warm
        $this->assertTrue(Cache::has(Config::MAP_CACHE_KEY));

        Config::flushMapCache();
        $this->assertFalse(Cache::has(Config::MAP_CACHE_KEY));
    }

    public function test_map_uses_table_configs(): void
    {
        $this->assertSame('configs', (new Config())->getTable());
    }
}
