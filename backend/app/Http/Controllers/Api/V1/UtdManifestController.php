<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Support\UtdManifest;
use Illuminate\Http\JsonResponse;

/**
 * Design-time discovery for UTD Studio.
 *
 * Implements the contract in utdStack/docs/INTEGRATION.md §2–3:
 *   GET /api/utd/manifest                 — packages + elements + action_elements
 *   GET /api/utd/packages/{key}/sample    — optional realistic preview data
 *
 * Both are protected by the `utd.secret` middleware (X-UTD-Secret).
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
            'packages' => UtdManifest::all(),
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
}
