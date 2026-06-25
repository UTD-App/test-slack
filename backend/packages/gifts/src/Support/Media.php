<?php

namespace Utd\Gifts\Support;

use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Resolves stored gift media (uploaded to the public disk) to an absolute URL the
 * app can load directly. Values that are already absolute URLs pass through, so
 * legacy/seeded URL values keep working.
 */
class Media
{
    public static function url(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        if (Str::startsWith($path, ['http://', 'https://'])) {
            return $path;
        }

        return Storage::disk('public')->url(ltrim($path, '/'));
    }
}
