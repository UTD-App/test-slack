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

    /**
     * Resolve a stored media value to a URL that loads in the ADMIN WEB browser.
     *
     * url() is correct for the mobile app, but the dashboard runs in a desktop
     * browser that can't reach a mobile-only public-disk host such as the Android
     * emulator's 10.0.2.2 (STORAGE_PUBLIC_URL). So the rules differ here:
     *   - cloud-backed media (GCS/S3 with a bucket) → the absolute cloud URL
     *   - local public-disk media                   → a HOST-RELATIVE /storage/…
     *     path, so it loads from whatever host serves the panel
     *   - bare relative paths are resolved through url() first
     *   - our own absolute URLs that embed /storage/<tail> are re-resolved from the
     *     <tail> (so a stored emulator host doesn't leak into the panel)
     *   - any other external absolute URL (CDN, ui-avatars, pravatar) passes through
     *
     * Use this for every image rendered in the admin panel.
     */
    public function webUrl(?string $path): ?string
    {
        if ($path === null || $path === '') {
            return null;
        }

        if (preg_match('#^https?://#i', $path)) {
            // Re-resolve our own stored media; leave third-party URLs untouched.
            if (preg_match('#/storage/(.+)$#', $path, $m)) {
                $path = $m[1];
            } else {
                return $path;
            }
        } else {
            $path = ltrim($path, '/');
        }

        $url = $this->url($path);

        // Keep absolute ONLY when the file truly lives on a public cloud bucket
        // (mirrors url()'s own branching); otherwise strip to a host-relative path
        // for the dashboard host.
        $driver   = $this->get('storage_driver', 'gcs');
        $bucket   = $this->get('storage_bucket');
        $endpoint = $this->get('storage_endpoint');
        $isCloud  = ($driver === 's3' && $endpoint && $bucket) || ($driver === 'gcs' && $bucket);

        return $isCloud ? $url : $this->toHostRelativeUrl($url);
    }

    /** Strip scheme+host from a URL so it resolves against the current request host. */
    private function toHostRelativeUrl(string $url): string
    {
        $p = parse_url($url, PHP_URL_PATH);

        if (empty($p)) {
            return $url;
        }

        $q = parse_url($url, PHP_URL_QUERY);

        return $p . ($q ? '?' . $q : '');
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

        // Resolve a relative key path against the project root. The Google client
        // reads the key file relative to the PHP process' working directory, which
        // under php-fpm/nginx is usually public/ (not the project root) — so a
        // relative GOOGLE_CLOUD_KEY_FILE like "service-account.json" fails on real
        // requests with "Given keyfile path ... does not exist" (yet works in
        // tinker, where the CWD happens to be the project root).
        if (is_string($keyFilePath) && $keyFilePath !== '' && ! $this->isAbsolutePath($keyFilePath)) {
            $keyFilePath = base_path($keyFilePath);
        }

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

    /**
     * Whether $path is absolute: Unix "/..." or Windows "C:\..." / "C:/...".
     */
    private function isAbsolutePath(string $path): bool
    {
        return (bool) preg_match('#^(/|[A-Za-z]:[\\\\/])#', $path);
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
