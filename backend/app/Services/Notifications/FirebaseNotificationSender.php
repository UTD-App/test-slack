<?php

namespace App\Services\Notifications;

use App\Contracts\NotificationSender;
use App\Models\User;
use App\Services\FirebaseConfigService;
use App\Support\Notifications\NotificationMessage;

/**
 * Default notification sender — delegates to the existing FirebaseConfigService
 * (FCM legacy HTTP) which reads its server key from App Settings (DB).
 */
class FirebaseNotificationSender implements NotificationSender
{
    public function __construct(protected FirebaseConfigService $firebase)
    {
    }

    public function send(User $user, NotificationMessage $message): bool
    {
        $token = $user->device_token;
        if (empty($token)) {
            return false;
        }

        return $this->firebase->sendNotification($token, $message->title, $message->body, $this->payloadData($message));
    }

    public function sendToTokens(array $tokens, NotificationMessage $message): void
    {
        foreach (array_filter($tokens) as $token) {
            $this->firebase->sendNotification($token, $message->title, $message->body, $this->payloadData($message));
        }
    }

    public function sendToTopic(string $topic, NotificationMessage $message): bool
    {
        // FCM legacy accepts "/topics/<name>" in the `to` field.
        return $this->firebase->sendNotification("/topics/{$topic}", $message->title, $message->body, $this->payloadData($message));
    }

    protected function payloadData(NotificationMessage $message): array
    {
        $data = $message->data;
        if ($message->imageUrl) {
            $data['image'] = $message->imageUrl;
        }

        return $data;
    }
}
