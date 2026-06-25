<?php

namespace Utd\Gifts\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

/**
 * A single admin-tunable Gifts setting (key/value). Read/written through
 * Support\GiftSettings, which caches the whole set under 'gifts:settings';
 * any write here busts that cache.
 */
class GiftSetting extends Model
{
    protected $fillable = ['key', 'value'];

    /** Bust the cached settings whenever one changes. */
    protected static function booted(): void
    {
        $forget = fn () => Cache::forget('gifts:settings');
        static::saved($forget);
        static::deleted($forget);
    }
}
