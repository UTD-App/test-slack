<?php

namespace Utd\Gifts\Support;

use Illuminate\Support\Facades\Cache;
use Utd\Gifts\Models\GiftSetting;

/**
 * Thin cached accessor over the gift_settings key/value table. Admin overrides
 * live in the DB; anything unset falls back to the config('gifts.*') default,
 * so the package works out of the box before anyone touches the settings page.
 *
 * The known EXP rates:
 *   exp_per_coin     — EXP a sender gains per 1 coin spent
 *   exp_per_diamond  — EXP a receiver gains per 1 diamond earned
 */
class GiftSettings
{
    /** Cache TTL (seconds) for the whole settings map. */
    private const TTL = 1800;

    /** A setting value, falling back to config('gifts.<key>', $default). */
    public static function get(string $key, mixed $default = null): mixed
    {
        $value = self::all()[$key] ?? null;

        if ($value === null) {
            return config("gifts.{$key}", $default);
        }

        return $value;
    }

    /** A setting cast to float (the EXP rates). */
    public static function float(string $key, float $default = 1.0): float
    {
        return (float) self::get($key, $default);
    }

    /** Persist a setting (busts the cache via the model's saved hook). */
    public static function set(string $key, mixed $value): void
    {
        GiftSetting::updateOrCreate(['key' => $key], ['value' => $value]);
    }

    /** All settings as [key => value] (cached). */
    public static function all(): array
    {
        return Cache::remember('gifts:settings', self::TTL, fn () => GiftSetting::query()
            ->pluck('value', 'key')
            ->all());
    }

    /** Drop the cached settings (e.g. after a bulk write). */
    public static function forget(): void
    {
        Cache::forget('gifts:settings');
    }
}
