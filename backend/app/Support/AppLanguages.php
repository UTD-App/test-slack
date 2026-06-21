<?php

namespace App\Support;

use App\Models\Language;
use Illuminate\Support\Facades\Cache;

/**
 * Cached view of the configured app languages (the `languages` table). Used by
 * the translatable-content system so resolving a localized value never costs a
 * query per attribute, and so admin forms / middleware can list the available
 * locales.
 *
 * Resilient by design: if the `languages` table isn't migrated yet (fresh
 * install / early boot / some tests) every accessor degrades to en/ar — the
 * same fallback {@see \App\Http\Middleware\SetAdminLocale} uses.
 */
final class AppLanguages
{
    private const TTL_MINUTES = 30;
    private const CODES_KEY   = 'app.languages.active_codes';
    private const DEFAULT_KEY = 'app.languages.default_code';
    private const RTL_KEY      = 'app.languages.rtl_codes';
    private const NAMES_KEY    = 'app.languages.names';

    /**
     * Active language codes, default language first (so the resolver's
     * insertion-order fallback prefers it).
     *
     * @return array<int,string>
     */
    public static function activeCodes(): array
    {
        return Cache::remember(self::CODES_KEY, now()->addMinutes(self::TTL_MINUTES), function () {
            try {
                $codes = Language::query()
                    ->where('is_active', true)
                    ->orderByDesc('is_default')
                    ->orderBy('id')
                    ->pluck('code')
                    ->all();
            } catch (\Throwable) {
                $codes = [];
            }

            return $codes !== [] ? $codes : ['en', 'ar'];
        });
    }

    /** The default language code (falls back to config('app.locale')). */
    public static function defaultCode(): string
    {
        return Cache::remember(self::DEFAULT_KEY, now()->addMinutes(self::TTL_MINUTES), function () {
            try {
                $code = Language::query()->where('is_default', true)->value('code');
            } catch (\Throwable) {
                $code = null;
            }

            return $code ?: (string) config('app.locale', 'en');
        });
    }

    /**
     * RTL language codes among the active languages.
     *
     * @return array<int,string>
     */
    public static function rtlCodes(): array
    {
        return Cache::remember(self::RTL_KEY, now()->addMinutes(self::TTL_MINUTES), function () {
            try {
                return Language::query()
                    ->where('is_active', true)
                    ->where('is_rtl', true)
                    ->pluck('code')
                    ->all();
            } catch (\Throwable) {
                return ['ar'];
            }
        });
    }

    /**
     * Native display names of the active languages, keyed by code
     * (e.g. ['en' => 'English', 'ar' => 'العربية']). Used for admin form labels.
     *
     * @return array<string,string>
     */
    public static function names(): array
    {
        return Cache::remember(self::NAMES_KEY, now()->addMinutes(self::TTL_MINUTES), function () {
            try {
                return Language::query()
                    ->where('is_active', true)
                    ->pluck('native_name', 'code')
                    ->all();
            } catch (\Throwable) {
                return ['en' => 'English', 'ar' => 'العربية'];
            }
        });
    }

    public static function isActive(string $code): bool
    {
        return in_array($code, self::activeCodes(), true);
    }

    /** Drop the cached language metadata (called when a language row changes). */
    public static function flush(): void
    {
        Cache::forget(self::CODES_KEY);
        Cache::forget(self::DEFAULT_KEY);
        Cache::forget(self::RTL_KEY);
        Cache::forget(self::NAMES_KEY);
    }
}
