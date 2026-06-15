<?php

namespace App\Contributors;

use App\Contracts\UserDataContributor;
use App\Models\Notification;
use App\Models\User;

/**
 * Adds the `notifications` block to GET /api/my-data so the app can show an
 * unread badge without a second request. Registered in
 * {@see \App\Providers\NotificationServiceProvider}.
 */
class NotificationDataContributor implements UserDataContributor
{
    public function getKey(): string
    {
        return 'notifications';
    }

    public function getUserData(User $user): ?array
    {
        return [
            'unread_count' => Notification::query()
                ->forUser($user->id)
                ->whereNull('read_at')
                ->count(),
        ];
    }
}
