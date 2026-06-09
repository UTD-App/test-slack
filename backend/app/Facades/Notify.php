<?php

namespace App\Facades;

use App\Contracts\NotificationSender;
use App\Models\User;
use App\Support\Notifications\NotificationMessage;
use Illuminate\Support\Facades\Facade;

/**
 * @method static bool send(User $user, NotificationMessage $message)
 * @method static void sendToTokens(array $tokens, NotificationMessage $message)
 * @method static bool sendToTopic(string $topic, NotificationMessage $message)
 *
 * @see \App\Contracts\NotificationSender
 */
class Notify extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return NotificationSender::class;
    }
}
