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

        // Design-time contract for UTD Studio (GET /api/utd/manifest). Guarded so
        // the package still boots on a base that lacks the Studio infra.
        if (class_exists(\App\Support\UtdManifest::class)) {
            \App\Support\UtdManifest::registerPackage(
                require self::PACKAGE_ROOT . '/config/utd_manifest.php'
            );
        }

        if ($this->app->make(PackageRegistry::class)->isEnabled('moment') && class_exists(ProfileContributorRegistry::class)) {
            $this->app->make(ProfileContributorRegistry::class)->register(new MomentProfileContributor());
        }

        // Contribute a "Reports filed" tab to the base User profile. Injects the
        // relation onto the base User (so base never references ReportMoment) and
        // registers the RelationManager with the base tab registry. Guarded so the
        // package still boots on a base without the registry.
        if ($this->app->make(PackageRegistry::class)->isEnabled('moment')
            && class_exists(\App\Support\UserProfileTabRegistry::class)) {
            \App\Models\User::resolveRelationUsing(
                'momentReportsFiled',
                fn (\App\Models\User $user) => $user->hasMany(
                    \Utd\Moment\Entities\ReportMoment::class,
                    'Reporter_id',
                    'id'
                )
            );

            // This user's own moments (separate from reports they filed).
            \App\Models\User::resolveRelationUsing(
                'userMoments',
                fn (\App\Models\User $user) => $user->hasMany(
                    \Utd\Moment\Entities\Moment::class,
                    'user_id',
                    'id'
                )
            );

            $registry = $this->app->make(\App\Support\UserProfileTabRegistry::class);
            // Tab order: Reports (10) → Gifts received (20) → sent (30) → Reels (40) → Moments (50).
            $registry->register(
                'moment-reports-filed',
                \Utd\Moment\Filament\Resources\UserResource\RelationManagers\MomentReportsFiledRelationManager::class,
                10,
            );
            $registry->register(
                'moment-user',
                \Utd\Moment\Filament\Resources\UserResource\RelationManagers\UserMomentsRelationManager::class,
                50,
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
            $this->loadTranslationsFrom($langPath, 'moment');

            // Contribute the Flutter `moment.*` UI strings to the backend translation
            // catalog (resources/lang/<locale>/moment.php) so they're served via
            // /api/translations + editable from the dashboard. Guarded for older bases.
            if (class_exists(\App\Services\TranslationGroupRegistry::class)) {
                $this->app->make(\App\Services\TranslationGroupRegistry::class)
                    ->register('moment', $langPath);
            }
        }
    }
}
