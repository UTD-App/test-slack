<?php

namespace App\Exceptions;

use Exception;
use Throwable;

/**
 * Thrown when writing an uploaded file to the configured storage disk fails
 * (e.g. GCS/S3 returns 403 for read-only credentials, or the bucket is
 * misconfigured). Lets the API return a clean envelope instead of a raw 500.
 */
class MediaUploadException extends Exception
{
    public function __construct(string $message = 'Media upload failed', ?Throwable $previous = null)
    {
        parent::__construct($message, 0, $previous);
    }

    public function getStatusCode(): int
    {
        return 500;
    }
}
