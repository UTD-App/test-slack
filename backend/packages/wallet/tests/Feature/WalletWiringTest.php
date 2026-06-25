<?php

namespace Utd\Wallet\Tests\Feature;

use App\Contracts\WalletContract;
use App\Exceptions\WalletProviderMissingException;
use App\Models\User;
use App\Services\PackageRegistry;
use App\Services\Wallet\NullWallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;
use Utd\Wallet\Services\DatabaseWallet;

/**
 * Package wiring: the provider binds the real wallet, registers itself, exposes
 * its config, routes and translations, and degrades to NullWallet when disabled.
 */
class WalletWiringTest extends TestCase
{
    use RefreshDatabase;

    public function test_contract_is_bound_to_database_wallet(): void
    {
        $this->assertInstanceOf(DatabaseWallet::class, app(WalletContract::class));
        $this->assertTrue(app(WalletContract::class)->isAvailable());
    }

    public function test_config_defaults(): void
    {
        $this->assertTrue(config('wallet.enabled'));
        $this->assertSame('coins', config('wallet.default_currency'));
        $this->assertContains('coins', config('wallet.currencies'));
    }

    public function test_degrades_to_null_wallet_when_disabled(): void
    {
        config(['wallet.enabled' => false]);
        app()->forgetInstance(WalletContract::class);

        $wallet = app(WalletContract::class);
        $this->assertInstanceOf(NullWallet::class, $wallet);
        $this->assertFalse($wallet->isAvailable());
        $this->assertSame(0.0, $wallet->getBalance(User::factory()->create(), 'coins'));

        $this->expectException(WalletProviderMissingException::class);
        $wallet->credit(User::factory()->create(), 'coins', 10, 'admin_charge');
    }

    public function test_api_routes_are_registered(): void
    {
        $uris = collect(Route::getRoutes()->getRoutes())->map->uri()->all();

        $this->assertContains('api/wallet/balances', $uris);
        $this->assertContains('api/wallet/transactions', $uris);
        $this->assertContains('api/coins', $uris);
        $this->assertContains('api/coins/payment-methods', $uris);
    }

    public function test_translations_are_loaded(): void
    {
        $this->assertNotSame('wallet::admin.nav_charges', __('wallet::admin.nav_charges'));
        $this->assertNotSame('wallet::admin.nav_wallet_transactions', __('wallet::admin.nav_wallet_transactions'));
    }

    public function test_package_is_registered_with_the_registry(): void
    {
        $manifests = app(PackageRegistry::class)->all();

        $this->assertArrayHasKey('wallet', $manifests);
        $this->assertSame('Wallet', $manifests['wallet']['name']);
    }
}
