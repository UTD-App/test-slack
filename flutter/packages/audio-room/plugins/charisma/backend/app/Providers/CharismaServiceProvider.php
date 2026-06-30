<?php

namespace App\Providers;

use App\Events\Gifts\GiftSent;
use App\Listeners\UpdateCharismaOnGiftSent;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\ServiceProvider;

class CharismaServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        $this->loadRoutesFrom(__DIR__ . '/../../routes/api.php');
        $this->loadMigrationsFrom(__DIR__ . '/../../database/migrations');

        Event::listen(GiftSent::class, UpdateCharismaOnGiftSent::class);
    }
}
