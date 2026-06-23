<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\TranslationKey;
use App\Services\TranslationLoader;
use App\Support\UtdManifest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Design-time discovery for UTD Studio.
 *
 * Implements the contract in utdStack/docs/INTEGRATION.md §2–3:
 *   GET  /api/utd/manifest               — packages + elements + action_elements
 *                                          + app.locales + translations catalog
 *   GET  /api/utd/packages/{key}/sample  — optional realistic preview data
 *   GET  /api/utd/translations           — Studio pull: full locale-first catalog
 *   POST /api/utd/translations           — write-back: Studio saves edited strings
 *
 * All protected by the `utd.secret` middleware (X-UTD-Secret).
 */
class UtdManifestController extends Controller
{
    // GET /api/utd/manifest
    public function manifest(): JsonResponse
    {
        return response()->json([
            'version'  => '1',
            'app'      => [
                'name'           => config('app.name'),
                'default_locale' => config('app.locale', 'ar'),
                'locales'        => $this->locales(),
            ],
            // Full translation catalog so Studio can show + edit every UI string
            // per language inline (key → { locale: value }). Source of truth stays
            // the dashboard; Studio reads here and writes back via POST below.
            'translations' => $this->translations(),
            'packages' => UtdManifest::all(),
        ]);
    }

    /**
     * POST /api/utd/translations — Studio write-back.
     *
     * Primary shape (UTD Studio sync contract) — LOCALE-FIRST catalog:
     *   { "translations": { "ar": { "app.login": "…" }, "en": { "app.login": "Login" } },
     *     "locales": [...], "default_locale": "ar", "version": "…" }
     *   (also tolerates the enveloped { "data": { "translations": { … } } })
     *
     * Legacy shapes still accepted:
     *   { "key": "app.login", "values": { "ar": "…", "en": "…" } }
     *   { "items": [ { "key": "...", "values": { ... } }, ... ] }
     *
     * Keys are stored verbatim (no `t.` prefix — that lives only in screen
     * bindings). Each value is upserted into the SAME lang-file store the
     * dashboard writes to (single source of truth), the key is registered, and
     * each touched locale's version is bumped so devices re-fetch.
     */
    public function saveTranslations(Request $request): JsonResponse
    {
        $loader        = app(TranslationLoader::class);
        $activeLocales = $this->locales();
        $touched       = [];
        $written       = 0;

        // Preferred: locale-first catalog { locale: { key: value } }.
        $catalog = $request->input('translations');
        if (! is_array($catalog)) {
            $catalog = $request->input('data.translations'); // enveloped fallback
        }

        if (is_array($catalog)) {
            foreach ($catalog as $locale => $pairs) {
                if (! is_string($locale) || ! in_array($locale, $activeLocales, true) || ! is_array($pairs)) {
                    continue; // ignore unknown locales / malformed entries
                }

                // Batch writes per lang-file group (one file write per group).
                $byGroup = [];
                foreach ($pairs as $key => $value) {
                    if (! is_string($key) || $key === '' || ! str_contains($key, '.') || ! is_string($value)) {
                        continue;
                    }
                    $group = explode('.', $key)[0];
                    TranslationKey::firstOrCreate(['key' => $key], ['group' => $group]);
                    $byGroup[$group][$key] = $value;
                }

                foreach ($byGroup as $group => $map) {
                    $written += $loader->writeGroupValues($locale, $group, $map);
                }
                if ($byGroup !== []) {
                    $touched[$locale] = true;
                }
            }
        } else {
            // Legacy: { key, values } or { items: [ { key, values } ] }.
            $items = $request->input('items');
            if (! is_array($items)) {
                $items = [[
                    'key'    => $request->input('key'),
                    'values' => $request->input('values', []),
                ]];
            }

            foreach ($items as $item) {
                $key    = is_array($item) ? ($item['key'] ?? null) : null;
                $values = (is_array($item) && is_array($item['values'] ?? null)) ? $item['values'] : [];
                if (! is_string($key) || $key === '' || ! str_contains($key, '.')) {
                    continue;
                }

                $group = explode('.', $key)[0];
                TranslationKey::firstOrCreate(['key' => $key], ['group' => $group]);

                foreach ($values as $locale => $value) {
                    if (! is_string($locale) || ! in_array($locale, $activeLocales, true) || ! is_string($value)) {
                        continue;
                    }
                    $written += $loader->writeGroupValues($locale, $group, [$key => $value]);
                    $touched[$locale] = true;
                }
            }
        }

        foreach (array_keys($touched) as $locale) {
            $loader->clearCache($locale); // forget cache + bump translations_version_<locale>
        }

        return response()->json([
            'status'          => true,
            'message'         => '',
            'data'            => ['upserted' => $written],
            // legacy fields kept for any existing caller
            'written'         => $written,
            'updated_locales' => array_keys($touched),
        ]);
    }

    // GET /api/utd/packages/{key}/sample
    public function sample(string $key): JsonResponse
    {
        $package = UtdManifest::get($key);

        if (! $package) {
            return response()->json(['error' => 'not_found', 'message' => "Unknown package '{$key}'"], 404);
        }

        return response()->json(['items' => $package['sample'] ?? []]);
    }

    /** Active locales from the languages table, falling back to ar/en. */
    protected function locales(): array
    {
        try {
            $codes = \App\Models\Language::query()
                ->when(
                    \Illuminate\Support\Facades\Schema::hasColumn('languages', 'is_active'),
                    fn ($q) => $q->where('is_active', true)
                )
                ->pluck('code')
                ->filter()
                ->values()
                ->all();

            return $codes ?: ['ar', 'en'];
        } catch (\Throwable) {
            return ['ar', 'en'];
        }
    }

    /**
     * Full translation catalog for Studio, LOCALE-FIRST `{ locale: { key: value } }`
     * (the shape the UTD Studio sync channel consumes — see the i18n sync contract).
     * Built from the SAME source the app + dashboard use (TranslationLoader), so
     * Studio shows exactly what the device will render. Keys are the catalog keys
     * verbatim (e.g. `app.login`) — the `t.` namespace lives only in screen bindings
     * and is stripped by the app at render, never stored here.
     */
    protected function translations(): array
    {
        try {
            $loader = app(TranslationLoader::class);
            $out = [];
            foreach ($this->locales() as $code) {
                $out[$code] = $loader->getForLocale($code); // { key: value }
            }

            return $out;
        } catch (\Throwable) {
            return [];
        }
    }

    /**
     * GET /api/utd/translations — Studio pull.
     *
     * Dedicated read endpoint the Studio hits on "Sync from Base". Returns the
     * full locale-first catalog plus the active locales, the default locale, and a
     * content fingerprint the Studio may use to skip no-op syncs.
     */
    public function pullTranslations(): JsonResponse
    {
        $translations = $this->translations();

        return response()->json([
            'version'        => md5(json_encode($translations)),
            'default_locale' => config('app.locale', 'ar'),
            'locales'        => $this->locales(),
            'translations'   => $translations,
        ]);
    }
}
