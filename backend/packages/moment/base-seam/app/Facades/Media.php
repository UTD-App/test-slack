<?php

namespace App\Facades;

use App\Contracts\MediaUploader;
use App\Support\Media\MediaResult;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Facade;

/**
 * @method static MediaResult upload(UploadedFile $file, string $folder = 'uploads', array $options = [])
 * @method static MediaResult putContents(string $path, string $contents, array $options = [])
 * @method static string url(string $path)
 * @method static bool delete(string $path)
 *
 * @see \App\Contracts\MediaUploader
 */
class Media extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return MediaUploader::class;
    }
}
