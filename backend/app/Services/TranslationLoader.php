<?php

namespace App\Services;

use App\Models\Config;
use App\Models\Language;
use App\Models\Translation;
use App\Models\TranslationKey;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\File;

class TranslationLoader
{
    // Scan lang/en/*.php and return all keys as flat dot-notation
    public function scanLangFiles(string $locale = 'en'): array
    {
        $path = resource_path("lang/{$locale}");

        if (!File::isDirectory($path)) {
            return [];
        }

        $result = [];

        foreach (File::files($path) as $file) {
            if ($file->getExtension() !== 'php') continue;

            $group  = $file->getFilenameWithoutExtension();
            $values = include $file->getPathname();

            if (!is_array($values)) continue;

            foreach ($this->flatten($values, "{$group}") as $key => $value) {
                $result[$key] = $value;
            }
        }

        return $result;
    }

    // Sync lang/en/ keys into translation_keys table
    public function syncKeysFromFiles(): int
    {
        $keys  = $this->scanLangFiles('en');
        $count = 0;

        foreach ($keys as $dotKey => $value) {
            $group = explode('.', $dotKey)[0];

            TranslationKey::firstOrCreate(
                ['key' => $dotKey],
                ['group' => $group]
            );

            $count++;
        }

        return $count;
    }

    // Get all translations for a locale as flat array
    // DB overrides file values
    public function getForLocale(string $locale): array
    {
        $cacheKey = "translations.{$locale}";

        return Cache::remember($cacheKey, now()->addMinutes(30), function () use ($locale) {
            $fileValues = $this->scanLangFiles($locale);

            $language = Language::where('code', $locale)->first();
            if (!$language) {
                return $fileValues;
            }

            $dbValues = Translation::where('language_id', $language->id)
                ->with('key')
                ->get()
                ->mapWithKeys(fn($t) => [$t->key->key => $t->value])
                ->filter()
                ->toArray();

            return array_merge($fileValues, $dbValues);
        });
    }

    // Get all keys with their English values and DB translations for a language
    public function getKeysForAdmin(Language $language, ?string $group = null): array
    {
        $englishValues = $this->scanLangFiles('en');

        $dbValues = Translation::where('language_id', $language->id)
            ->with('key')
            ->get()
            ->mapWithKeys(fn($t) => [$t->key->key => $t->value])
            ->toArray();

        $result = [];

        foreach ($englishValues as $key => $english) {
            if ($group && !str_starts_with($key, $group . '.')) continue;

            $result[] = [
                'key'         => $key,
                'group'       => explode('.', $key)[0],
                'english'     => $english,
                'translation' => $dbValues[$key] ?? null,
            ];
        }

        return $result;
    }

    // Flatten nested array to dot notation
    private function flatten(array $array, string $prefix = ''): array
    {
        $result = [];

        foreach ($array as $key => $value) {
            $fullKey = $prefix ? "{$prefix}.{$key}" : $key;

            if (is_array($value)) {
                $result = array_merge($result, $this->flatten($value, $fullKey));
            } else {
                $result[$fullKey] = (string) $value;
            }
        }

        return $result;
    }

    // Clear translation cache for a locale + bump version (devices will re-fetch)
    public function clearCache(string $locale): void
    {
        Cache::forget("translations.{$locale}");
        Config::updateOrCreate(
            ['name' => "translations_version_{$locale}"],
            ['value' => (string) now()->timestamp]
        );
    }

    // Clear all translation caches
    public function clearAllCaches(): void
    {
        Language::pluck('code')->each(fn($code) => $this->clearCache($code));
    }
}
