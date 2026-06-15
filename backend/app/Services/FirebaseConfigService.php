<?php

namespace App\Services;

use App\Models\Config;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FcmNotification;

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
            config(['services.firebase.server_key' => $serverKey]);
        }

        if ($projectId && $serverKey) {
            config([
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
     * Send an FCM push to a device token via the modern HTTP v1 API (kreait,
     * OAuth from a service-account JSON). The legacy `fcm/send` + server-key
     * endpoint this used to call was shut down by Google in 2024.
     *
     * Returns false (never throws) when no service account is configured or the
     * send fails, so callers degrade gracefully.
     */
    public function sendNotification(string $deviceToken, string $title, string $body, array $data = []): bool
    {
        $credentials = $this->credentialsPath();
        if (! $credentials) {
            return false;
        }

        try {
            $messaging = (new Factory())->withServiceAccount($credentials)->createMessaging();

            $message = CloudMessage::withTarget('token', $deviceToken)
                ->withNotification(FcmNotification::create($title, $body))
                ->withData(array_map(static fn ($v) => (string) $v, $data));

            $messaging->send($message);

            return true;
        } catch (\Throwable $e) {
            Log::warning('FCM v1 send failed: ' . $e->getMessage());

            return false;
        }
    }

    /** Locate the FCM v1 service-account JSON (DB setting → FILE_NAME → default storage path). */
    public function credentialsPath(): ?string
    {
        $candidates = [
            $this->get('firebase_credentials_path'),
            env('FILE_NAME') ? base_path((string) env('FILE_NAME')) : null,
            storage_path('app/firebase/service-account.json'),
        ];

        foreach ($candidates as $path) {
            if ($path && is_file($path)) {
                return $path;
            }
        }

        return null;
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
