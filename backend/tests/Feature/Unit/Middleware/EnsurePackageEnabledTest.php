<?php

namespace Tests\Feature\Unit\Middleware;

use App\Models\Package;
use App\Services\PackageRegistry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class EnsurePackageEnabledTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Bust the enabled/disabled slug caches between tests.
        app(PackageRegistry::class)->forgetCache();
    }

    private function defineRoute(string $slug): void
    {
        Route::middleware(["package.enabled:{$slug}"])
            ->get('/_t/pkg', fn () => response()->json(['ok' => true]));
    }

    public function test_enabled_package_passes(): void
    {
        Package::create([
            'slug'    => 'moment',
            'name'    => 'Moment',
            'enabled' => true,
        ]);
        app(PackageRegistry::class)->forgetCache();

        $this->defineRoute('moment');

        $this->getJson('/_t/pkg')->assertStatus(200)->assertJsonPath('ok', true);
    }

    public function test_absent_package_row_is_treated_as_enabled(): void
    {
        // No row for 'reels' -> registry treats it as enabled (pre-sync modules work).
        $this->defineRoute('reels');

        $this->getJson('/_t/pkg')->assertStatus(200)->assertJsonPath('ok', true);
    }

    public function test_disabled_package_returns_403(): void
    {
        Package::create([
            'slug'    => 'moment',
            'name'    => 'Moment',
            'enabled' => false,
        ]);
        app(PackageRegistry::class)->forgetCache();

        $this->defineRoute('moment');

        $this->getJson('/_t/pkg')
            ->assertStatus(403)
            ->assertJsonPath('status', false);
    }
}
