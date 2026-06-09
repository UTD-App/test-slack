<?php

namespace App\Providers;

use App\Models\MenuItem;
use App\Models\Package;
use App\Observers\MenuItemObserver;
use App\Observers\PackageObserver;
use App\Services\FirebaseConfigService;
use App\Services\MenuService;
use App\Services\PackageRegistry;
use App\Services\ProfileContributorRegistry;
use App\Services\RoleService;
use App\Services\SettingService;
use App\Services\StorageConfigService;
use App\Services\TranslationLoader;
use App\Services\UserDataService;
use App\Services\UserSettingService;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Force HTTPS only in production; local dev runs over plain HTTP
        // (php artisan serve), so forcing https there breaks redirects/assets.
        if ($this->app->environment('production')) {
            URL::forceScheme('https');
        }

        $this->app->singleton(UserDataService::class);
        $this->app->singleton(RoleService::class);
        $this->app->singleton(UserSettingService::class);
        $this->app->singleton(StorageConfigService::class);
        $this->app->singleton(FirebaseConfigService::class);
        $this->app->singleton(TranslationLoader::class);

        // Package reception SDK
        $this->app->singleton(PackageRegistry::class);
        $this->app->singleton(MenuService::class);
        $this->app->singleton(SettingService::class);
        $this->app->singleton(ProfileContributorRegistry::class);

        if ($this->app->isLocal()) {
            $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
            $this->app->register(TelescopeServiceProvider::class);
        }
    }

    public function boot(): void
    {
        try {
            app(StorageConfigService::class)->configure();
            app(FirebaseConfigService::class)->configure();
        } catch (\Throwable) {
            // DB not ready yet (e.g. during migrations) — fall back to .env
        }

        // Expose the base app's own core screens (auth/profile/settings) to
        // UTD Studio, same mechanism a package uses from its ServiceProvider.
        if (class_exists(\App\Support\UtdManifest::class)) {
            \App\Support\UtdManifest::registerPackage(
                require config_path('utd_manifest_core.php')
            );
        }

        Package::observe(PackageObserver::class);
        MenuItem::observe(MenuItemObserver::class);
    }
}
