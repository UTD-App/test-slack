<?php

namespace App\Contracts;

use App\Models\User;
use App\Support\Notifications\NotificationType;

/**
 * A delivery channel for the high-level Notifier (NOT the low-level push
 * primitive — that is {@see NotificationSender}). The Base ships `database`
 * (in-app feed) and `push` (wraps NotificationSender). Plugins add more
 * (realtime, email, sms) by registering with the ChannelRegistry — no change
 * to the notification system itself.
 */
interface NotificationChannel
{
    /** Stable channel key, e.g. 'database', 'push'. Matches NotificationType::$channels. */
    public function key(): string;

    /**
     * Deliver one notification to one recipient.
     *
     * @param  User                 $recipient  who receives it
     * @param  NotificationType     $type       the registered type metadata
     * @param  array<string,mixed>  $payload    ['params'=>[], 'data'=>[], 'actor_id'=>?int,
     *                                            'image_url'=>?string, 'title'=>string, 'body'=>string]
     *                                            (`title`/`body` are pre-rendered in the recipient's locale)
     */
    public function deliver(User $recipient, NotificationType $type, array $payload): void;
}
