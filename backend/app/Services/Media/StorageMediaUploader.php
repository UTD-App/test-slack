<?php

namespace App\Services\Media;

use App\Contracts\MediaUploader;
use App\Exceptions\MediaUploadException;
use App\Services\StorageConfigService;
use App\Support\Media\MediaResult;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Default media uploader — uses Laravel's Storage (configured at boot by
 * StorageConfigService from the admin's chosen driver: local/s3/gcs/ftp/...).
 * Plain pass-through upload; an image-optimization plugin can override this.
 */
class StorageMediaUploader implements MediaUploader
{
    public function __construct(protected StorageConfigService $storage)
    {
    }

    public function upload(UploadedFile $file, string $folder = 'uploads', array $options = []): MediaResult
    {
        $extension = $file->getClientOriginalExtension() ?: $file->guessExtension() ?: 'bin';
        $name = ($options['name'] ?? (string) Str::uuid()) . '.' . $extension;
        $path = trim($folder, '/') . '/' . $name;

        $this->put($path, file_get_contents($file->getRealPath()), $options['visibility'] ?? 'public');

        return new MediaResult(
            path: $path,
            url: $this->url($path),
            disk: config('filesystems.default'),
            size: $file->getSize(),
            mime: $file->getMimeType(),
        );
    }

    public function putContents(string $path, string $contents, array $options = []): MediaResult
    {
        $path = ltrim($path, '/');
        $this->put($path, $contents, $options['visibility'] ?? 'public');

        return new MediaResult(
            path: $path,
            url: $this->url($path),
            disk: config('filesystems.default'),
            size: strlen($contents),
        );
    }

    /**
     * Writes to the configured disk, converting any driver failure (e.g. a GCS
     * 403 from read-only credentials) into a clean MediaUploadException so the
     * API returns a meaningful envelope instead of a raw 500.
     */
    protected function put(string $path, string $contents, string $visibility): void
    {
        try {
            $ok = Storage::put($path, $contents, $visibility);
        } catch (\Throwable $e) {
            Log::error('Media upload failed', [
                'path' => $path,
                'disk' => config('filesystems.default'),
                'error' => $e->getMessage(),
            ]);
            throw new MediaUploadException('Failed to store the uploaded file.', $e);
        }

        if ($ok === false) {
            Log::error('Media upload returned false', [
                'path' => $path,
                'disk' => config('filesystems.default'),
            ]);
            throw new MediaUploadException('Failed to store the uploaded file.');
        }
    }

    public function url(string $path): string
    {
        return $this->storage->url($path);
    }

    public function delete(string $path): bool
    {
        return Storage::delete($path);
    }
}
