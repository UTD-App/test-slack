<?php

namespace Utd\Wallet\Providers;

use App\Contracts\WalletContract;
use App\Services\PackageRegistry;
use App\Services\Wallet\NullWallet;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Utd\Wallet\Services\DatabaseWallet;

/**
 * Wallet package service provider (drop-in: copied into backend/packages/wallet,
 * auto-registered by the base PackageServiceProvider via extra.laravel.providers).
 *
 * Binds the Base WalletContract to DatabaseWallet (coins, extensible), or NullWallet
 * when disabled. Wires config, migrations, routes, translations, and self-registers
 * with the Base PackageRegistry. Filament resources are auto-discovered by the base
 * AdminPanelProvider from src/Filament/ — no manual plugin registration.
 */
class WalletServiceProvider extends ServiceProvider
{
    private const PACKAGE_ROOT = __DIR__ . '/../..';

    public function register(): void
    {
        $this->mergeConfigFrom(self::PACKAGE_ROOT . '/config/config.php', 'wallet');

        $this->app->singleton(
            WalletContract::class,
            fn () => config('wallet.enabled', true) ? new DatabaseWallet() : new NullWallet(),
        );
    }

    public function boot(): void
    {
        $this->app->make(PackageRegistry::class)->register([
            'slug'         => 'wallet',
            'name'         => 'Wallet',
            'version'      => '1.0.0',
            'is_core'      => false,
            'dependencies' => [],
        ]);

        $this->loadMigrationsFrom(self::PACKAGE_ROOT . '/database/migrations');
        $this->registerTranslations();
        $this->loadRoutes();

        // Design-time contract for UTD Studio (GET /api/utd/manifest) — exposes
        // `wallet.balance` so the coin card can be bound on a Studio screen.
        // Guarded so the package still boots on a base without the Studio infra.
        if (class_exists(\App\Support\UtdManifest::class)) {
            \App\Support\UtdManifest::registerPackage(
                require self::PACKAGE_ROOT . '/config/utd_manifest.php'
            );
        }
    }

    protected function loadRoutes(): void
    {
        Route::prefix('api')
            ->middleware('api')
            ->group(self::PACKAGE_ROOT . '/routes/api.php');
    }

    protected function registerTranslations(): void
    {
        $langPath = self::PACKAGE_ROOT . '/resources/lang';

        if (is_dir($langPath)) {
            $this->loadTranslationsFrom($langPath, 'wallet');

            // Contribute the Flutter `wallet.*` UI strings to the backend translation
            // catalog (resources/lang/<locale>/wallet.php) so they're served via
            // /api/translations + editable from the dashboard. Guarded for older bases.
            if (class_exists(\App\Services\TranslationGroupRegistry::class)) {
                $this->app->make(\App\Services\TranslationGroupRegistry::class)
                    ->register('wallet', $langPath);
            }
        }
    }
}
