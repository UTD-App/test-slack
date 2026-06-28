<?php

namespace Utd\Reels\Providers;

use App\Services\Notifications\NotificationTypeRegistry;
use App\Services\PackageRegistry;
use App\Services\ProfileContributorRegistry;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Utd\Reels\Profile\ReelsProfileContributor;

/**
 * Reels package service provider.
 *
 * This is a STANDALONE composer package (namespace Utd\Reels), installed
 * manually (drop-in): it is NOT an nwidart module and is NOT auto-discovered by
 * a Modules/ scan. Registration is manual — see INSTALL.md. This provider wires
 * up config, migrations, routes, and self-registers with the Base PackageRegistry.
 *
 * Filament admin resources are registered separately via Utd\Reels\Filament\ReelsPlugin
 * (added by hand to AdminPanelProvider — see INSTALL.md).
 *
 * Video → poster-frame extraction runs through pbmedia/laravel-ffmpeg (a package
 * require), which auto-discovers its own provider — nothing extra needed here.
 */
class ReelsServiceProvider extends ServiceProvider
{
    private const PACKAGE_ROOT = __DIR__ . '/../..';

    public function boot(): void
    {
        // Self-register so `php artisan utd:sync-packages` persists this package.
        $this->app->make(PackageRegistry::class)->register([
            'slug'         => 'reels',
            'name'         => 'Reels',
            'version'      => '1.0.0',
            'is_core'      => false,
            'dependencies' => [],
        ]);

        $this->mergeConfigFrom(self::PACKAGE_ROOT . '/config/config.php', 'reels');
        $this->loadMigrationsFrom(self::PACKAGE_ROOT . '/database/migrations');
        $this->loadViewsFrom(self::PACKAGE_ROOT . '/resources/views', 'reels');
        $this->registerTranslations();
        $this->loadRoutes();

        if ($this->app->make(PackageRegistry::class)->isEnabled('reels') && class_exists(ProfileContributorRegistry::class)) {
            $this->app->make(ProfileContributorRegistry::class)->register(new ReelsProfileContributor());
        }

        $this->registerProfileTab();
        $this->registerNotifications();
    }

    /**
     * Contribute a "Reels" tab (this user's reels) to the base User profile.
     * Injects a `userReels` relation onto the base User + registers the read-only
     * RelationManager with the base tab registry. Lazy + paginated. Guarded.
     */
    protected function registerProfileTab(): void
    {
        if (! $this->app->make(PackageRegistry::class)->isEnabled('reels')
            || ! class_exists(\App\Support\UserProfileTabRegistry::class)) {
            return;
        }

        \App\Models\User::resolveRelationUsing(
            'userReels',
            fn (\App\Models\User $user) => $user->hasMany(\Utd\Reels\Entities\Real::class, 'user_id', 'id'),
        );

        $this->app->make(\App\Support\UserProfileTabRegistry::class)->register(
            'reels-user',
            \Utd\Reels\Filament\Resources\UserResource\RelationManagers\UserReelsRelationManager::class,
            40,
        );
    }

    /**
     * Register Reels notification types with the Base notification system
     * (no-op if it isn't installed). Sending happens in the like/comment
     * controllers (to the reel owner) and the report controller (to admins).
     */
    protected function registerNotifications(): void
    {
        if (! $this->app->bound(NotificationTypeRegistry::class)) {
            return;
        }

        $types = $this->app->make(NotificationTypeRegistry::class);

        $types->register('reels.like', [
            'category' => 'reels',
            'body_key' => 'reels::notifications.liked',
            'channels' => ['database', 'push'],
            'icon'     => 'heart',
            'route'    => '/reels/:reel_id',
        ]);

        $types->register('reels.comment', [
            'category' => 'reels',
            'body_key' => 'reels::notifications.commented',
            'channels' => ['database', 'push'],
            'icon'     => 'chat-bubble-left',
            'route'    => '/reels/:reel_id',
        ]);

        $types->register('reels.comment.like', [
            'category' => 'reels',
            'body_key' => 'reels::notifications.comment_liked',
            'channels' => ['database', 'push'],
            'icon'     => 'heart',
            'route'    => '/reels/:reel_id',
        ]);

        $types->register('reels.gift', [
            'category' => 'reels',
            'body_key' => 'reels::notifications.gifted',
            'channels' => ['database', 'push'],
            'icon'     => 'gift',
            'route'    => '/reels/:reel_id',
        ]);

        // Admin/dashboard audience (Notifier::toAdmins) — moderation queue.
        $types->register('reels.report', [
            'category' => 'report',
            'body_key' => 'reels::notifications.reported',
            'channels' => ['database'],
            'icon'     => 'flag',
        ]);
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
            $this->loadTranslationsFrom($langPath, 'reels');

            // Contribute the Flutter `reels.*` UI strings to the backend translation
            // catalog (resources/lang/<locale>/reels.php) so they're served via
            // /api/translations + editable from the dashboard. Guarded for older bases.
            if (class_exists(\App\Services\TranslationGroupRegistry::class)) {
                $this->app->make(\App\Services\TranslationGroupRegistry::class)
                    ->register('reels', $langPath);
            }
        }
    }
}
