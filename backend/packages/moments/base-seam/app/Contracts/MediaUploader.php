<?php

namespace App\Contracts;

use App\Support\Media\MediaResult;
use Illuminate\Http\UploadedFile;

/**
 * Media upload primitive. Packages upload through this contract instead of
 * touching Storage directly. The Base ships a Storage-backed default (honouring
 * the admin's storage driver); an image-optimization plugin can override it.
 */
interface MediaUploader
{
    /** Store an uploaded file under $folder; returns its path + public URL. */
    public function upload(UploadedFile $file, string $folder = 'uploads', array $options = []): MediaResult;

    /** Store raw contents at an explicit path. */
    public function putContents(string $path, string $contents, array $options = []): MediaResult;

    /** Public URL for a stored path. */
    public function url(string $path): string;

    /** Delete a stored file. */
    public function delete(string $path): bool;
}
