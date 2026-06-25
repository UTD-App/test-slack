<?php

namespace Utd\Gifts\Providers;

use App\Contracts\GiftDirectory;
use App\Contracts\GiftSender;
use App\Services\PackageRegistry;
use App\Services\ProfileContributorRegistry;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Utd\Gifts\Profile\GiftsProfileContributor;
use Utd\Gifts\Services\GiftDirectoryService;
use Utd\Gifts\Services\GiftSendingService;

/**
 * Gifts package service provider (standalone Utd\Gifts, manual drop-in — see INSTALL.md).
 *
 * Binds the Base GiftSender to GiftSendingService (spend coins → earn diamonds via
 * the Wallet) and GiftDirectory to GiftDirectoryService (aggregation for Moment etc).
 * Installing this package lights up gifting everywhere it's wired (Moment now).
 * Filament resources are registered via Utd\Gifts\Filament\GiftsPlugin.
 */
class GiftsServiceProvider extends ServiceProvider
{
    private const PACKAGE_ROOT = __DIR__ . '/../..';

    public function register(): void
    {
        $this->mergeConfigFrom(self::PACKAGE_ROOT . '/config/config.php', 'gifts');

        if (config('gifts.enabled', true)) {
            $this->app->singleton(GiftSender::class, GiftSendingService::class);
            $this->app->singleton(GiftDirectory::class, GiftDirectoryService::class);
        }
    }

    public function boot(): void
    {
        $this->app->make(PackageRegistry::class)->register([
            'slug'         => 'gifts',
            'name'         => 'Gifts',
            'version'      => '1.0.0',
            'is_core'      => false,
            'dependencies' => ['wallet'],
        ]);

        $this->ensureEarnCurrency();
        $this->loadMigrationsFrom(self::PACKAGE_ROOT . '/database/migrations');
        $this->registerTranslations();
        $this->registerViews();
        $this->loadRoutes();
        $this->registerProfileSection();
        $this->registerProfileTabs();

        if ($this->app->runningInConsole()) {
            $this->commands([\Utd\Gifts\Console\Commands\BackfillGiftExp::class]);
        }
    }

    /**
     * Gifts introduce an EARNING currency (diamonds) the Wallet package doesn't
     * ship by default — it owns coins only. Register it on the Wallet at runtime
     * so the receiver credit is accepted, instead of editing the Wallet package:
     * each consumer lights up the currency it needs (the same way Agency/Target
     * would add theirs). No-op if it's already registered.
     */
    protected function ensureEarnCurrency(): void
    {
        $earn = trim((string) config('gifts.earn_currency', 'diamonds'));
        if ($earn === '') {
            return;
        }

        $currencies = (array) config('wallet.currencies', ['coins']);
        if (! in_array($earn, $currencies, true)) {
            config(['wallet.currencies' => array_values(array_unique([...$currencies, $earn]))]);
        }
    }

    /** Contribute the "received gifts" section to the Profile package (when enabled). */
    protected function registerProfileSection(): void
    {
        $registry = $this->app->make(PackageRegistry::class);

        if ($registry->isEnabled('gifts') && class_exists(ProfileContributorRegistry::class)) {
            $this->app->make(ProfileContributorRegistry::class)->register(new GiftsProfileContributor());
        }
    }

    /**
     * Contribute "Gifts received" + "Gifts sent" tabs to the base User profile.
     * Injects the relations onto the base User (so base never references GiftLog)
     * and registers the read-only RelationManagers with the base tab registry.
     * Lazy + paginated → no cost on profile page load. Guarded for older bases.
     */
    protected function registerProfileTabs(): void
    {
        if (! $this->app->make(PackageRegistry::class)->isEnabled('gifts')
            || ! class_exists(\App\Support\UserProfileTabRegistry::class)) {
            return;
        }

        \App\Models\User::resolveRelationUsing(
            'giftsReceived',
            fn (\App\Models\User $user) => $user->hasMany(\Utd\Gifts\Models\GiftLog::class, 'receiver_id', 'id'),
        );
        \App\Models\User::resolveRelationUsing(
            'giftsSent',
            fn (\App\Models\User $user) => $user->hasMany(\Utd\Gifts\Models\GiftLog::class, 'sender_id', 'id'),
        );

        $registry = $this->app->make(\App\Support\UserProfileTabRegistry::class);
        $registry->register('gifts-received', \Utd\Gifts\Filament\Resources\UserResource\RelationManagers\GiftsReceivedRelationManager::class, 20);
        $registry->register('gifts-sent', \Utd\Gifts\Filament\Resources\UserResource\RelationManagers\GiftsSentRelationManager::class, 30);
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
            $this->loadTranslationsFrom($langPath, 'gifts');

            // Contribute the Flutter `gifts.*` UI strings to the backend translation
            // catalog (resources/lang/<locale>/gifts.php) so they're served via
            // /api/translations + editable from the dashboard. Guarded for older bases.
            if (class_exists(\App\Services\TranslationGroupRegistry::class)) {
                $this->app->make(\App\Services\TranslationGroupRegistry::class)
                    ->register('gifts', $langPath);
            }
        }
    }

    /** Register the 'gifts::' view namespace (Filament table column renderers). */
    protected function registerViews(): void
    {
        $viewPath = self::PACKAGE_ROOT . '/resources/views';

        if (is_dir($viewPath)) {
            $this->loadViewsFrom($viewPath, 'gifts');
        }
    }
}
