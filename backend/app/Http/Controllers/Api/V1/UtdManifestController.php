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
     * Body (either shape):
     *   { "key": "auth.login", "values": { "ar": "تسجيل دخول", "en": "Login" } }
     *   { "items": [ { "key": "...", "values": { ... } }, ... ] }
     *
     * Upserts each value into the SAME lang-file store the dashboard writes to
     * (single source of truth), registers the key, and bumps each locale's
     * version so devices re-fetch. Mirrors the admin "Translations" page exactly.
     */
    public function saveTranslations(Request $request): JsonResponse
    {
        $loader = app(TranslationLoader::class);

        $items = $request->input('items');
        if (! is_array($items)) {
            $items = [[
                'key'    => $request->input('key'),
                'values' => $request->input('values', []),
            ]];
        }

        $activeLocales = $this->locales();
        $touched = [];
        $written = 0;

        foreach ($items as $item) {
            $key    = is_array($item) ? ($item['key'] ?? null) : null;
            $values = (is_array($item) && is_array($item['values'] ?? null)) ? $item['values'] : [];
            if (! is_string($key) || $key === '' || ! str_contains($key, '.')) {
                continue;
            }

            $group = explode('.', $key)[0];
            TranslationKey::firstOrCreate(['key' => $key], ['group' => $group]);

            foreach ($values as $locale => $value) {
                if (! is_string($locale) || ! in_array($locale, $activeLocales, true)) {
                    continue; // ignore unknown locales
                }
                if (! is_string($value)) {
                    continue;
                }
                $written += $loader->writeGroupValues($locale, $group, [$key => $value]);
                $touched[$locale] = true;
            }
        }

        foreach (array_keys($touched) as $locale) {
            $loader->clearCache($locale); // forget cache + bump translations_version_<locale>
        }

        return response()->json([
            'status'          => true,
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
     * Full translation catalog for Studio, keyed `key → { locale: value }`, so
     * every translatable string carries ALL its languages in ONE manifest call.
     * Built from the SAME source the app + dashboard use (TranslationLoader), so
     * Studio shows exactly what the device will render.
     */
    protected function translations(): array
    {
        try {
            $loader = app(TranslationLoader::class);
            $out = [];
            foreach ($this->locales() as $code) {
                foreach ($loader->getForLocale($code) as $key => $value) {
                    $out[$key][$code] = $value;
                }
            }

            return $out;
        } catch (\Throwable) {
            return [];
        }
    }
}
