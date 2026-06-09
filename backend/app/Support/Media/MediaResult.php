<?php

namespace App\Support\Media;

/**
 * Outcome of a media upload.
 */
class MediaResult
{
    public function __construct(
        public readonly string $path,
        public readonly string $url,
        public readonly ?string $disk = null,
        public readonly ?int $size = null,
        public readonly ?string $mime = null,
    ) {
    }

    public function toArray(): array
    {
        return [
            'path' => $this->path,
            'url'  => $this->url,
            'disk' => $this->disk,
            'size' => $this->size,
            'mime' => $this->mime,
        ];
    }
}
