<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\Config;
use App\Models\Language;
use App\Services\TranslationLoader;

class TranslationController extends Controller
{
    public function __construct(private TranslationLoader $loader) {}

    // GET /api/translations/supported
    public function supported(): \Illuminate\Http\JsonResponse
    {
        $languages = Language::where('is_active', true)
            ->select('code', 'name', 'native_name', 'is_rtl', 'is_default')
            ->get();

        return Common::apiResponse(true, '', $languages);
    }

    // GET /api/translations/{locale}/version
    // Returns only the version timestamp — tiny request, no data
    // Flutter calls this on every launch to decide if re-fetch is needed
    public function version(string $locale): \Illuminate\Http\JsonResponse
    {
        $version = Config::where('name', "translations_version_{$locale}")->value('value')
            ?? '0';

        return Common::apiResponse(true, '', ['version' => $version, 'locale' => $locale]);
    }

    // GET /api/translations/{locale}
    // Returns ALL translations as flat JSON — called only when version changed
    public function index(string $locale): \Illuminate\Http\JsonResponse
    {
        $translations = $this->loader->getForLocale($locale);
        $version      = Config::where('name', "translations_version_{$locale}")->value('value') ?? '0';

        return Common::apiResponse(true, '', [
            'version'      => $version,
            'locale'       => $locale,
            'translations' => $translations,
        ]);
    }
}
