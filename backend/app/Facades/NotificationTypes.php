<?php

namespace App\Facades;

use App\Services\Notifications\NotificationTypeRegistry;
use App\Support\Notifications\NotificationType;
use Illuminate\Support\Facades\Facade;

/**
 * Catalogue of notification types. A package registers its types once in its
 * provider boot():
 *
 *   NotificationTypes::register('social.follow', [
 *       'category' => 'social',
 *       'body_key' => 'social::notifications.follow',     // ':name followed you'
 *       'channels' => ['database', 'push'],
 *       'route'    => '/profile/:user_id',
 *   ]);
 *
 * @method static void register(string $key, array $meta)
 * @method static bool has(string $key)
 * @method static NotificationType|null get(string $key)
 * @method static array all()
 * @method static array categories()
 *
 * @see \App\Services\Notifications\NotificationTypeRegistry
 */
class NotificationTypes extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return NotificationTypeRegistry::class;
    }
}
