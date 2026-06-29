<?php

namespace Tests\Feature\Unit\Middleware;

use App\Models\Config;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class StacAuthMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    private function defineRoute(): void
    {
        Route::middleware(['stac.auth'])
            ->get('/_t/stac', fn () => response()->json(['ok' => true]));
    }

    public function test_without_key_configured_returns_401(): void
    {
        // No utd_stac_key in config -> always unauthorized (fail closed).
        $this->defineRoute();

        $this->getJson('/_t/stac')->assertStatus(401);
    }

    public function test_correct_key_passes(): void
    {
        Config::create(['name' => 'utd_stac_key', 'value' => 'stac-key']);
        $this->defineRoute();

        $this->getJson('/_t/stac', ['X-Stac-Key' => 'stac-key'])
            ->assertStatus(200)
            ->assertJsonPath('ok', true);
    }

    public function test_wrong_key_returns_401(): void
    {
        Config::create(['name' => 'utd_stac_key', 'value' => 'stac-key']);
        $this->defineRoute();

        $this->getJson('/_t/stac', ['X-Stac-Key' => 'wrong'])
            ->assertStatus(401);
    }

    public function test_missing_header_returns_401_when_configured(): void
    {
        Config::create(['name' => 'utd_stac_key', 'value' => 'stac-key']);
        $this->defineRoute();

        $this->getJson('/_t/stac')->assertStatus(401);
    }
}
