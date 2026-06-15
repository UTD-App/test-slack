<?php

namespace App\Facades;

use App\Models\User;
use Illuminate\Support\Facades\Facade;

/**
 * High-level notification entry point. Any package notifies a user by TYPE and
 * gets in-app storage + push + recipient-locale localization + preference
 * checks in one call:
 *
 *   Notifier::send($user, 'social.follow',
 *       params: ['name' => $actor->name], data: ['user_id' => $actor->id], actor: $actor);
 *
 * Distinct from {@see Notify} (low-level raw push, no storage).
 *
 * @method static void send(User $recipient, string $typeKey, array $params = [], array $data = [], ?User $actor = null, ?string $imageUrl = null)
 * @method static void sendMany(iterable $recipients, string $typeKey, array $params = [], array $data = [], ?User $actor = null, ?string $imageUrl = null)
 * @method static void broadcast(string $typeKey, array $params = [], array $data = [], ?array $userIds = null)
 * @method static void toAdmins(string $typeKey, array $params = [], array $data = [], ?User $actor = null)
 *
 * @see \App\Services\Notifications\NotificationManager
 */
class Notifier extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return 'utd.notifier';
    }
}
