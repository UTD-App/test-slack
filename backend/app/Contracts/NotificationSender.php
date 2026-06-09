<?php

namespace App\Contracts;

use App\Models\User;
use App\Support\Notifications\NotificationMessage;

/**
 * Push-notification primitive. Packages send notifications through this
 * contract instead of talking to FCM/SMS directly. The Base ships a
 * Firebase-backed default; channel plugins (SMS, WhatsApp) can override.
 */
interface NotificationSender
{
    /** Send to a single user (uses the user's device token). */
    public function send(User $user, NotificationMessage $message): bool;

    /** Send to explicit device tokens. */
    public function sendToTokens(array $tokens, NotificationMessage $message): void;

    /** Send to an FCM topic. */
    public function sendToTopic(string $topic, NotificationMessage $message): bool;
}
