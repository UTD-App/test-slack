<?php

namespace Utd\AudioRoom\Providers;

use App\Services\PackageRegistry;
use App\Services\UserDataService;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Utd\AudioRoom\Contracts\AudioRoomDataContributor;

class AudioRoomServiceProvider extends ServiceProvider
{
    private const PACKAGE_ROOT = __DIR__ . '/../..';

    public function register(): void
    {
        $this->mergeConfigFrom(self::PACKAGE_ROOT . '/config/audio-room.php', 'audio-room');
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
    }

    protected function loadRoutes(): void
    {
        Route::prefix('api')
            ->middleware('api')
            ->group(self::PACKAGE_ROOT . '/routes/api.php');
    }
}
