<?php

namespace App\Providers;

use App\Contracts\NotificationSender;
use App\Contributors\NotificationDataContributor;
use App\Notifications\Channels\DatabaseChannel;
use App\Notifications\Channels\PushChannel;
use App\Services\Notifications\ChannelRegistry;
use App\Services\Notifications\NotificationManager;
use App\Services\Notifications\NotificationTypeRegistry;
use App\Services\UserDataService;
use Illuminate\Support\ServiceProvider;

/**
 * Wires the high-level notification system that lives in the Base:
 *  - the type catalogue (NotificationTypeRegistry / NotificationTypes facade)
 *  - the channel registry + built-in channels (database always, push toggleable)
 *  - the NotificationManager (Notifier facade) packages call to notify users
 *  - the my-data unread badge contributor
 *
 * Registered BEFORE PackageServiceProvider in config/app.php so the registries
 * exist when package providers register their own types/channels in boot().
 */
class NotificationServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../../config/notifications.php', 'notifications');

        $this->app->singleton(NotificationTypeRegistry::class);
        $this->app->singleton(ChannelRegistry::class);
        $this->app->singleton(NotificationManager::class);

        // Facade accessor for App\Facades\Notifier.
        $this->app->singleton('utd.notifier', fn ($app) => $app->make(NotificationManager::class));
    }

    public function boot(): void
    {
        $channels = $this->app->make(ChannelRegistry::class);

        // The in-app feed channel is always on.
        $channels->register($this->app->make(DatabaseChannel::class));

        // Push wraps the existing low-level NotificationSender (Firebase by default).
        if (config('notifications.channels.push', true)) {
            $channels->register(new PushChannel($this->app->make(NotificationSender::class)));
        }

        $this->registerCoreTypes($this->app->make(NotificationTypeRegistry::class));

        // Unread badge in /api/my-data.
        $this->app->make(UserDataService::class)->register(
            $this->app->make(NotificationDataContributor::class),
        );
    }

    /**
     * Notification types owned by the Base. Feature packages register their own
     * types in their providers via NotificationTypes::register().
     */
    protected function registerCoreTypes(NotificationTypeRegistry $types): void
    {
        $types->register('system.announcement', [
            'category' => 'system',
            'body_key' => 'notifications.announcement', // free-text; params carry a per-locale body map
            'channels' => ['database', 'push'],
            'icon'     => 'megaphone',
        ]);

        $types->register('system.welcome', [
            'category' => 'system',
            'body_key' => 'notifications.welcome',
            'channels' => ['database'],
            'icon'     => 'hand-wave',
        ]);
    }
}
