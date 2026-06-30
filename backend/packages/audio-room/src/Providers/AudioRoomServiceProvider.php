<?php

namespace Utd\AudioRoom\Providers;

use App\Contracts\RoomOwnerResolver;
use App\Events\Gifts\GiftSent;
use App\Services\PackageRegistry;
use App\Services\UserDataService;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Utd\AudioRoom\Contracts\AudioRoomDataContributor;
use Utd\AudioRoom\Entities\Room;
use Utd\AudioRoom\Listeners\UpdateCharismaOnGiftSent;

class AudioRoomServiceProvider extends ServiceProvider
{
    private const PACKAGE_ROOT = __DIR__ . '/../..';

    public function register(): void
    {
        $this->mergeConfigFrom(self::PACKAGE_ROOT . '/config/audio-room.php', 'audio-room');

        // Trusted room-owner lookup for the Gifts room-owner cut. Resolving the
        // owner from our own table (not the client request) closes the IDOR where
        // a sender could redirect another room's cut to themselves.
        $this->app->bind(RoomOwnerResolver::class, function () {
            return new class implements RoomOwnerResolver {
                public function ownerId(int $roomId): ?int
                {
                    $ownerId = Room::query()->whereKey($roomId)->value('user_id');

                    return $ownerId ? (int) $ownerId : null;
                }
            };
        });
    }

    public function boot(): void
    {
        $this->app->make(PackageRegistry::class)->register([
            'slug'         => 'audio-room',
            'name'         => 'Audio Room',
            'version'      => '1.0.0',
            'is_core'      => false,
            'dependencies' => [],
        ]);

        $this->loadMigrationsFrom(self::PACKAGE_ROOT . '/database/migrations');
        $this->loadRoutes();

        $this->app->make(UserDataService::class)->register(new AudioRoomDataContributor());

        Event::listen(GiftSent::class, UpdateCharismaOnGiftSent::class);
    }

    protected function loadRoutes(): void
    {
        Route::prefix('api')
            ->middleware('api')
            ->group(self::PACKAGE_ROOT . '/routes/api.php');
    }
}
