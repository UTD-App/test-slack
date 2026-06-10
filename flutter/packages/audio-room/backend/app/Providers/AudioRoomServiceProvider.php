<?php

namespace App\Providers;

use App\Contracts\AudioRoomDataContributor;
use App\Contracts\MenuContributor;
use App\Services\MenuService;
use App\Services\UserDataService;
use Illuminate\Support\ServiceProvider;

class AudioRoomServiceProvider extends ServiceProvider implements MenuContributor
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        $this->loadRoutesFrom(__DIR__ . '/../../routes/api.php');
        $this->loadMigrationsFrom(__DIR__ . '/../../database/migrations');

        app(UserDataService::class)->register(new AudioRoomDataContributor());
        app(MenuService::class)->register($this);
    }

    public function getPackage(): string
    {
        return 'audio-room';
    }

    public function getMenuItems(): array
    {
        return [
            [
                'slug'      => 'audio-room.lobby',
                'label_key' => 'audio_room.menu_lobby',
                'slot'      => 'bottomNav',
                'icon'      => 'mic',
                'order'     => 20,
                'target'    => 'app',
            ],
        ];
    }
}
