<?php

namespace App\Services;

use App\Models\Config;

class FirebaseConfigService
{
    public function configure(): void
    {
        $projectId = $this->get('firebase_project_id');
        $serverKey = $this->get('firebase_server_key');

        if ($projectId) {
            // Override kreait/laravel-firebase project config from DB
            config(['firebase.projects.app.project_id' => $projectId]);
        }

        if ($serverKey) {
            // Used for sending FCM notifications directly
            config(['services.firebase.server_key' => $serverKey]);
        }

        // If both are set, override the credentials path so kreait uses DB values
        if ($projectId && $serverKey) {
            config([
                'firebase.projects.app.credentials' => null,
                'firebase.projects.app.database_url' => "https://{$projectId}-default-rtdb.firebaseio.com",
            ]);
        }
    }

    public function getServerKey(): ?string
    {
        return $this->get('firebase_server_key') ?? env('FIREBASE_SERVER_KEY');
    }

    public function getProjectId(): ?string
    {
        return $this->get('firebase_project_id') ?? env('FIREBASE_PROJECT_ID');
    }

    /**
     * Send FCM push notification to a device token.
     * Uses server key from DB (configured via App Settings).
     */
    public function sendNotification(string $deviceToken, string $title, string $body, array $data = []): bool
    {
        $serverKey = $this->getServerKey();
        if (!$serverKey) {
            return false;
        }

        $payload = [
            'to'           => $deviceToken,
            'notification' => compact('title', 'body'),
            'data'         => $data,
        ];

        $ch = curl_init('https://fcm.googleapis.com/fcm/send');
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                "Authorization: key={$serverKey}",
            ],
            CURLOPT_POSTFIELDS => json_encode($payload),
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        return $httpCode === 200;
    }

    private function get(string $key, mixed $default = null): mixed
    {
        try {
            return Config::where('name', $key)->value('value') ?? $default;
        } catch (\Throwable) {
            return $default;
        }
    }
}
