<?php

namespace App\Models;

use App\Support\Auditable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class Config extends Model
{
    use Auditable;

    protected $table = 'configs';

    protected $guarded = [];

    protected $casts = [
        'is_hidden' => 'boolean',
    ];

    /** Cache key for the full name=>value map. */
    public const MAP_CACHE_KEY = 'configs.map';

    /**
     * The whole config table as a cached name=>value map (uses the configured
     * cache store — Redis in production). Auto-invalidated on any write below, so
     * hot read paths (e.g. the public /app-version gate) never touch the DB once
     * warm. Read a single key with `Config::map()[$name] ?? $default`.
     */
    public static function map(): array
    {
        return Cache::rememberForever(
            self::MAP_CACHE_KEY,
            fn () => static::query()->pluck('value', 'name')->all()
        );
    }

    public static function flushMapCache(): void
    {
        Cache::forget(self::MAP_CACHE_KEY);
    }

    protected static function booted(): void
    {
        // Any insert/update/delete of a config row drops the cached map, so the
        // next read rebuilds it — admin edits take effect immediately.
        static::saved(fn () => self::flushMapCache());
        static::deleted(fn () => self::flushMapCache());
    }
}
