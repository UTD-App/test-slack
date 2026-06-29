<?php

namespace Tests\Feature\Unit\Middleware;

use App\Models\Config;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class VerifyUtdSecretTest extends TestCase
{
    use RefreshDatabase;

    private function defineRoute(): void
    {
        Route::middleware(['utd.secret'])
            ->get('/_t/utd-secret', fn () => response()->json(['ok' => true]));
    }

    public function test_allowed_in_dev_when_secret_unset(): void
    {
        // No utd_secret configured -> dev mode allows the request through.
        $this->defineRoute();

        $this->getJson('/_t/utd-secret')->assertStatus(200)->assertJsonPath('ok', true);
    }

    public function test_correct_secret_passes(): void
    {
        Config::create(['name' => 'utd_secret', 'value' => 's3cr3t']);
        $this->defineRoute();

        $this->getJson('/_t/utd-secret', ['X-UTD-Secret' => 's3cr3t'])
            ->assertStatus(200)
            ->assertJsonPath('ok', true);
    }

    public function test_wrong_secret_returns_401(): void
    {
        Config::create(['name' => 'utd_secret', 'value' => 's3cr3t']);
        $this->defineRoute();

        $this->getJson('/_t/utd-secret', ['X-UTD-Secret' => 'nope'])
            ->assertStatus(401)
            ->assertJsonPath('error', 'unauthorized');
    }

    public function test_missing_secret_header_returns_401_when_configured(): void
    {
        Config::create(['name' => 'utd_secret', 'value' => 's3cr3t']);
        $this->defineRoute();

        $this->getJson('/_t/utd-secret')->assertStatus(401);
    }
}
