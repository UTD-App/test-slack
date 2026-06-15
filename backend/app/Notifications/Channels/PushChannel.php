<?php

namespace App\Notifications\Channels;

use App\Contracts\NotificationChannel;
use App\Contracts\NotificationSender;
use App\Models\User;
use App\Support\Notifications\NotificationMessage;
use App\Support\Notifications\NotificationType;

/**
 * Push channel — a thin adapter over the existing low-level {@see NotificationSender}
 * (Firebase by default; a channel plugin can rebind it). The high-level Notifier
 * has already rendered `title`/`body` in the recipient's locale before this runs.
 * The `data` payload carries the type + deep-link so the app can route on tap.
 */
class PushChannel implements NotificationChannel
{
    public function __construct(protected NotificationSender $sender)
    {
    }

    public function key(): string
    {
        return 'push';
    }

    public function deliver(User $recipient, NotificationType $type, array $payload): void
    {
        if (empty($recipient->device_token)) {
            return;
        }

        $data = array_merge($payload['data'] ?? [], [
            'type'     => $type->key,
            'category' => $type->category,
        ]);

        if ($type->route) {
            $data['route'] = $type->route;
        }

        $this->sender->send($recipient, new NotificationMessage(
            title: (string) ($payload['title'] ?? ''),
            body: (string) ($payload['body'] ?? ''),
            data: $data,
            imageUrl: $payload['image_url'] ?? null,
        ));
    }
}
