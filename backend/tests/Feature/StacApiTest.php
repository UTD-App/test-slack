<?php

namespace Tests\Feature;

use App\Models\Config;
use App\Models\StacScreen;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StacApiTest extends TestCase
{
    use RefreshDatabase;

    private string $stacKey = 'test-stac-key-123';

    protected function setUp(): void
    {
        parent::setUp();
        Config::create(['name' => 'utd_stac_key', 'value' => $this->stacKey]);
    }

    public function test_stac_index_returns_active_screens(): void
    {
        StacScreen::create([
            'name'      => 'home',
            'package'   => 'base',
            'version'   => '1',
            'content'   => ['type' => 'Scaffold'],
            'is_active' => true,
        ]);

        $this->getJson('/api/stac')
            ->assertStatus(200)
            ->assertJsonPath('status', true);
    }

    public function test_stac_push_requires_valid_key(): void
    {
        $this->postJson('/api/stac/push', [], ['X-Stac-Key' => 'wrong-key'])
            ->assertStatus(401);
    }

    public function test_stac_push_with_valid_key_succeeds(): void
    {
        $this->postJson('/api/stac/push', [
            'screens' => [[
                'name'      => 'home',
                'package'   => 'base',
                'version'   => '1',
                'content'   => ['type' => 'Scaffold'],
                'is_active' => true,
            ]],
        ], ['X-Stac-Key' => $this->stacKey])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('stac_screens', ['name' => 'home']);
    }
}
