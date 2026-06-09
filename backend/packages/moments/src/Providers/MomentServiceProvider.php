<?php

namespace Utd\Moment\Providers;

use App\Services\PackageRegistry;
use App\Services\ProfileContributorRegistry;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Utd\Moment\Profile\MomentProfileContributor;

/**
 * Moment package service provider.
 *
 * This is a STANDALONE composer package (namespace Utd\Moment), installed
 * manually (drop-in): it is NOT an nwidart module and is NOT auto-discovered by
 * a Modules/ scan. Registration is manual — see INSTALL.md. This provider wires
 * up config, migrations, routes, and self-registers with the Base PackageRegistry.
 *
 * Filament admin resources are registered separately via Utd\Moment\Filament\MomentPlugin
 * (added by hand to AdminPanelProvider — see INSTALL.md).
 */
class MomentServiceProvider extends ServiceProvider
{
    private const PACKAGE_ROOT = __DIR__ . '/../..';

    public function boot(): void
    {
        // Self-register so `php artisan utd:sync-packages` persists this package.
        $this->app->make(PackageRegistry::class)->register([
            'slug'         => 'moment',
            'name'         => 'Moment',
            'version'      => '1.0.0',
            'is_core'      => false,
            'dependencies' => [],
        ]);

        $this->mergeConfigFrom(self::PACKAGE_ROOT . '/config/config.php', 'moment');
        $this->loadMigrationsFrom(self::PACKAGE_ROOT . '/database/migrations');
        $this->loadViewsFrom(self::PACKAGE_ROOT . '/resources/views', 'moment');
        $this->registerTranslations();
        $this->loadRoutes();

        if ($this->app->make(PackageRegistry::class)->isEnabled('moment') && class_exists(ProfileContributorRegistry::class)) {
            $this->app->make(ProfileContributorRegistry::class)->register(new MomentProfileContributor());
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
            $this->loadTranslationsFrom($langPath, 'moment');
        }
    }
}
