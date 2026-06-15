<?php

namespace App\Services;

use App\Models\Config;

class StorageConfigService
{
    public function configure(): void
    {
        // GCS is the default provider.
        $driver = $this->get('storage_driver', 'gcs');

        if ($driver === 'local' || !$driver) {
            config(['filesystems.default' => 'public']);
            return;
        }

        $diskConfig = match ($driver) {
            's3'    => $this->s3Config(),
            'gcs'   => $this->gcsConfig(),
            'ftp'   => $this->ftpConfig(),
            'sftp'  => $this->sftpConfig(),
            default => null,
        };

        // Cloud drivers need a bucket. If one isn't configured yet (e.g. a fresh
        // install where gcs is the default but no credentials are set), stay on
        // the local public disk so uploads degrade gracefully instead of 500ing.
        if (!$diskConfig || (in_array($driver, ['s3', 'gcs'], true) && empty($diskConfig['bucket']))) {
            config(['filesystems.default' => 'public']);
            return;
        }

        // Register dynamic disk and set as default
        config(['filesystems.disks.app_storage' => $diskConfig]);
        config(['filesystems.default' => 'app_storage']);
    }

    /**
     * Get the URL for a stored file.
     * Works regardless of which storage driver is configured.
     */
    public function url(string $path): string
    {
        $driver   = $this->get('storage_driver', 'gcs');
        $endpoint = $this->get('storage_endpoint');
        $bucket   = $this->get('storage_bucket');

        if ($driver === 's3' && $endpoint && $bucket) {
            return rtrim($endpoint, '/') . '/' . $bucket . '/' . ltrim($path, '/');
        }

        if ($driver === 'gcs' && $bucket) {
            return "https://storage.googleapis.com/{$bucket}/" . ltrim($path, '/');
        }

        return \Illuminate\Support\Facades\Storage::url($path);
    }

    private function s3Config(): array
    {
        return [
            'driver'                  => 's3',
            'key'                     => $this->get('storage_key'),
            'secret'                  => $this->get('storage_secret'),
            'region'                  => $this->get('storage_region', 'us-east-1'),
            'bucket'                  => $this->get('storage_bucket'),
            'url'                     => $this->get('storage_endpoint'),
            'endpoint'                => $this->get('storage_endpoint') ?: null,
            'use_path_style_endpoint' => (bool) $this->get('storage_endpoint'),
            'visibility'              => 'public',
            'throw'                   => false,
        ];
    }

    private function gcsConfig(): array
    {
        // Static credentials come from the base's `gcs` disk defined in
        // config/filesystems.php — the only place env() is read, so this stays
        // correct under `php artisan config:cache` (env() outside config files
        // returns null once the config is cached). spatie expects the key PATH
        // in key_file_path (key_file is for an inline credentials array).
        $base = config('filesystems.disks.gcs', []);

        // Key file: prefer one uploaded from the admin panel (stored privately on
        // the `local` disk = storage/app), else the env-configured path, else the
        // conventional service-account.json at the project root.
        $uploaded = $this->get('storage_gcs_key_file');
        $keyFilePath = $uploaded
            ? storage_path('app/' . ltrim($uploaded, '/'))
            : ($base['key_file_path'] ?? base_path('service-account.json'));

        return [
            'driver'        => 'gcs',
            'key_file_path' => $keyFilePath,
            // Project id from the storage settings, falling back to the Firebase
            // project id, then the env-derived disk config.
            'project_id'    => $this->get('storage_project_id')
                ?: $this->get('firebase_project_id')
                ?: ($base['project_id'] ?? null),
            // Bucket is admin-configurable at runtime (DB), with an env-derived fallback.
            'bucket'        => $this->get('storage_bucket') ?: ($base['bucket'] ?? null),
            'visibility'    => 'public',
        ];
    }

    private function ftpConfig(): array
    {
        return [
            'driver'   => 'ftp',
            'host'     => $this->get('storage_endpoint'),
            'username' => $this->get('storage_key'),
            'password' => $this->get('storage_secret'),
        ];
    }

    private function sftpConfig(): array
    {
        return [
            'driver'   => 'sftp',
            'host'     => $this->get('storage_endpoint'),
            'username' => $this->get('storage_key'),
            'password' => $this->get('storage_secret'),
        ];
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
