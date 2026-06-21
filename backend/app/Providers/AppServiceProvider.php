<?php

namespace App\Providers;

use App\Contracts\NotificationSender;
use App\Models\MenuItem;
use App\Models\Package;
use App\Models\User;
use App\Observers\MenuItemObserver;
use App\Observers\PackageObserver;
use App\Services\FirebaseConfigService;
use App\Support\Notifications\NotificationMessage;
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
        $this->app->singleton(\App\Services\AdminPermissionRegistry::class);
        $this->app->singleton(ProfileContributorRegistry::class);
        $this->app->singleton(\App\Support\UserProfileTabRegistry::class);
        $this->app->singleton(\App\Support\UserProfileInfolistRegistry::class);

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

        // Register the CORE UTD Studio manifest (auth/home/profile/settings default
        // screens + their elements/actions). Packages register their own manifest
        // from their provider boot(). UTD Studio reads the aggregate via
        // GET /api/utd/manifest.
        if (class_exists(\App\Support\UtdManifest::class)) {
            \App\Support\UtdManifest::registerPackage(require config_path('utd_manifest_core.php'));
        }

        Package::observe(PackageObserver::class);
        MenuItem::observe(MenuItemObserver::class);

        // Force-logout a user the instant they're suspended (status flipped to 0):
        // push a 'banned' data message; the app clears its session on receipt.
        // Covers every ban path (UserResource ban, comment ban, …) in one place.
        User::updated(function (User $user): void {
            if ($user->wasChanged('status') && ! $user->status && app()->bound(NotificationSender::class)) {
                try {
                    app(NotificationSender::class)->send($user, NotificationMessage::make(
                        'Account suspended',
                        'Your account has been suspended.',
                        ['type' => 'banned', 'action' => 'logout'],
                    ));
                } catch (\Throwable) {
                    // A push failure must never block the ban itself.
                }
            }
        });
    }
}
