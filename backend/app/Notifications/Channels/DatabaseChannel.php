<?php

namespace App\Notifications\Channels;

use App\Contracts\NotificationChannel;
use App\Models\Notification;
use App\Models\User;
use App\Support\Notifications\NotificationType;

/**
 * The always-on channel: persists the notification row that backs the in-app
 * feed (GET /notifications) and the unread badge. Stores type + params only —
 * NOT the pre-rendered title/body — so the feed re-localizes on every read.
 */
class DatabaseChannel implements NotificationChannel
{
    public function key(): string
    {
        return 'database';
    }

    public function deliver(User $recipient, NotificationType $type, array $payload): void
    {
        Notification::create([
            'notifiable_type' => Notification::AUDIENCE_USER,
            'notifiable_id'   => $recipient->id,
            'type'          => $type->key,
            'category'      => $type->category,
            'params'        => $payload['params'] ?? [],
            'data'          => $payload['data'] ?? [],
            'actor_id'      => $payload['actor_id'] ?? null,
            'image_url'     => $payload['image_url'] ?? null,
        ]);
    }
}
