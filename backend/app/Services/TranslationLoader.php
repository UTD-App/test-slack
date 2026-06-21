<?php

namespace App\Services;

use App\Models\Config;
use App\Models\Language;
use App\Models\Translation;
use App\Models\TranslationKey;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\File;

class TranslationLoader
{
    // Scan lang/<locale>/*.php (+ package-registered groups) → flat dot-notation.
    public function scanLangFiles(string $locale = 'en'): array
    {
        // Start with package-registered group DEFAULTS (gifts/profile/…) so any
        // package's UI strings join the catalog + API payload. The app's own lang
        // dir is merged ON TOP below, so admin/AI overrides always win.
        $result = $this->scanRegisteredGroups($locale);

        $path = resource_path("lang/{$locale}");

        if (File::isDirectory($path)) {
            foreach (File::files($path) as $file) {
                if ($file->getExtension() !== 'php') continue;

                $group  = $file->getFilenameWithoutExtension();
                $values = include $file->getPathname();

                if (!is_array($values)) continue;

                foreach ($this->flatten($values, "{$group}") as $key => $value) {
                    $result[$key] = $value;
                }
            }
        }

        return $result;
    }

    /**
     * Read every package-registered UI group's default values for a locale
     * ({@see TranslationGroupRegistry}), flattened to dot-keys. DEFAULTS only —
     * {@see scanLangFiles()} overlays the app's own lang dir on top.
     */
    private function scanRegisteredGroups(string $locale): array
    {
        $result = [];

        foreach (app(TranslationGroupRegistry::class)->all() as $group => $langDir) {
            $file = "{$langDir}/{$locale}/{$group}.php";
            if (! is_file($file)) {
                continue;
            }
            $values = include $file;
            if (! is_array($values)) {
                continue;
            }
            foreach ($this->flatten($values, $group) as $key => $value) {
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
    // Lang FILES are the source of truth for UI strings (the admin "Translations"
    // page + AI-translate write them, and Laravel __() resolves from them). The
    // legacy `translations` DB table only fills keys a file doesn't have, so file
    // edits always win.
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

            return array_merge($dbValues, $fileValues);
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

    // ── Lang-FILE storage (UI strings live in lang/<locale>/<group>.php) ───────
    // UI translations are written to PHP lang files (NOT the DB) so Laravel's
    // __()/trans() — which the admin dashboard renders with — resolves them. The
    // dot-key's first segment is the group/file; the rest is the (possibly
    // nested) path inside it (e.g. validation.custom.email.required).

    /** Absolute path to a locale's group file, e.g. lang/fr/admin.php. */
    public function fileGroupPath(string $locale, string $group): string
    {
        return resource_path("lang/{$locale}/{$group}.php");
    }

    /** Load a locale's group file as an array (empty if it doesn't exist). */
    public function loadGroupFile(string $locale, string $group): array
    {
        $path = $this->fileGroupPath($locale, $group);
        if (! is_file($path)) {
            return [];
        }
        $values = include $path;

        return is_array($values) ? $values : [];
    }

    /** Read a single leaf value from the lang files, or null when absent. */
    public function getFileValue(string $locale, string $dotKey): ?string
    {
        [$group, $sub] = $this->splitDotKey($dotKey);
        $data  = $this->loadGroupFile($locale, $group);
        // Package UI groups store the full sub-key LITERALLY (flat); base groups
        // nest so Laravel __() resolves them. {@see isFlatGroup()}.
        $value = $this->isFlatGroup($group) ? ($data[$sub] ?? null) : Arr::get($data, $sub);

        return is_string($value) ? $value : null;
    }

    /**
     * Whether a group is stored FLAT (literal dotted sub-keys) rather than nested.
     * Package UI groups ({@see TranslationGroupRegistry}) are flat: their keys form
     * a flat namespace consumed only via the API (never Laravel __()), and a flat
     * map lets a leaf (`moment.report`) coexist with a subtree (`moment.report.spam`)
     * that a nested array cannot represent. Base groups (admin/validation/…) stay
     * nested so __()'s dotted lookup keeps working.
     */
    private function isFlatGroup(string $group): bool
    {
        return array_key_exists($group, app(TranslationGroupRegistry::class)->all());
    }

    /**
     * Merge translated leaves into a locale's group file (create dir/file if
     * needed), preserving existing values + nesting. $dotKeyToValue is keyed by
     * FULL dot keys (e.g. ['admin.save' => 'Sauvegarder']); only keys of this
     * group are applied. Returns the number of leaves written.
     */
    public function writeGroupValues(string $locale, string $group, array $dotKeyToValue): int
    {
        $data    = $this->loadGroupFile($locale, $group);
        $flat    = $this->isFlatGroup($group);
        $written = 0;

        foreach ($dotKeyToValue as $dotKey => $value) {
            [$g, $sub] = $this->splitDotKey($dotKey);
            if ($g !== $group || $sub === '' || ! is_string($value)) {
                continue;
            }
            if ($flat) {
                $data[$sub] = $value;          // literal dotted key (package groups)
            } else {
                Arr::set($data, $sub, $value); // nested (base groups → Laravel __())
            }
            $written++;
        }

        if ($written === 0) {
            return 0;
        }

        $dir = dirname($this->fileGroupPath($locale, $group));
        if (! is_dir($dir)) {
            File::makeDirectory($dir, 0755, true);
        }

        File::put(
            $this->fileGroupPath($locale, $group),
            "<?php\n\nreturn " . var_export($data, true) . ";\n"
        );

        return $written;
    }

    /** Split "group.a.b" into ['group', 'a.b']; "group" → ['group', '']. */
    private function splitDotKey(string $dotKey): array
    {
        $pos = strpos($dotKey, '.');
        if ($pos === false) {
            return [$dotKey, ''];
        }

        return [substr($dotKey, 0, $pos), substr($dotKey, $pos + 1)];
    }
}
