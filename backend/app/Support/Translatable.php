<?php

namespace App\Support;

/**
 * Read-side of the translatable-content system. Resolves a single localized
 * value out of a "keyed-by-locale" map (e.g. {"en":"Hello","fr":"Bonjour"}) for
 * the current (or a given) locale, with a fallback chain so a missing
 * translation never renders blank:
 *
 *   requested locale → default language ({@see AppLanguages::defaultCode()})
 *   → first non-empty value in the map → null.
 *
 * A value counts as "present" when it has any non-whitespace content, so empty
 * HTML such as "<p></p>" still wins over the fallback (the admin deliberately
 * left it blank); only truly empty/whitespace strings are skipped.
 *
 * Models expose this via {@see \App\Models\Concerns\HasTranslations} (->tr()).
 */
final class Translatable
{
    /**
     * @param  array<string,mixed>|null  $map
     */
    public static function resolve(?array $map, ?string $locale = null): ?string
    {
        if (empty($map)) {
            return null;
        }

        $locale ??= app()->getLocale();

        // 1. Requested locale.
        if (self::filled($map[$locale] ?? null)) {
            return (string) $map[$locale];
        }

        // 2. Default language.
        $default = AppLanguages::defaultCode();
        if ($default !== $locale && self::filled($map[$default] ?? null)) {
            return (string) $map[$default];
        }

        // 3. First non-empty value (insertion order; default is listed first).
        foreach ($map as $value) {
            if (self::filled($value)) {
                return (string) $value;
            }
        }

        return null;
    }

    /**
     * Like {@see resolve()} but never returns null.
     *
     * @param  array<string,mixed>|null  $map
     */
    public static function resolveOr(?array $map, ?string $locale = null, string $default = ''): string
    {
        return self::resolve($map, $locale) ?? $default;
    }

    /**
     * Whether a keyed-by-locale map has a non-empty value for $locale (same
     * "present" rule as resolve(): whitespace = missing, "<p></p>" = present).
     * Used to detect missing translations in the admin "Content translations" page.
     *
     * @param  array<string,mixed>|null  $map
     */
    public static function hasLocale(?array $map, string $locale): bool
    {
        return ! empty($map) && self::filled($map[$locale] ?? null);
    }

    private static function filled(mixed $value): bool
    {
        return is_string($value) ? trim($value) !== '' : ! empty($value);
    }
}
