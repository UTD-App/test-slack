<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\Config;
use Illuminate\Http\Request;

/**
 * Launch-time bootstrap + platform gate.
 *
 * Public (no auth) — the app calls this on launch, before login, to learn:
 *   - whether it must force an update or show a maintenance screen, and
 *   - the admin-managed branding (name/logo/support/links).
 * Every value has a safe default so the app never breaks on an empty config.
 * Driven from the `configs` table, edited under Admin → App Settings.
 *
 * GET /api/v1/app-version?platform=android&version=42
 *   - platform: android | ios | huawei  (defaults to android)
 *   - version : the running build number (integer); 0/missing = unknown
 */
class AppVersionController extends Controller
{
    private const PLATFORMS = ['android', 'ios', 'huawei'];

    public function check(Request $request)
    {
        $platform = in_array($request->query('platform'), self::PLATFORMS, true)
            ? $request->query('platform')
            : 'android';

        $version = (int) $request->query('version', 0);

        $configs = Config::whereIn('name', [
            'maintenance_mode',
            'maintenance_message',
            "{$platform}_min_version",
            "{$platform}_latest_version",
            "{$platform}_update_required",
            "{$platform}_store_url",
            // Branding / general app config
            'app_name',
            'app_description',
            'app_logo',
            'support_email',
            'support_phone',
            'privacy_url',
            'terms_url',
            // App colors (admin overrides; blank = app keeps its built-in color)
            'theme_primary',
            'theme_accent',
            'theme_bg_dark',
            'theme_bg_gradient_1',
            'theme_bg_gradient_2',
            'theme_bg_gradient_3',
            'theme_card_bg',
            'theme_card_border',
            'theme_text_primary',
            'theme_text_secondary',
        ])->pluck('value', 'name');

        $minVersion     = (int) ($configs["{$platform}_min_version"] ?? 0);
        $latestVersion  = (int) ($configs["{$platform}_latest_version"] ?? 0);
        $updateRequired = filter_var($configs["{$platform}_update_required"] ?? false, FILTER_VALIDATE_BOOLEAN);
        $storeUrl       = $configs["{$platform}_store_url"] ?? null;

        $maintenance        = filter_var($configs['maintenance_mode'] ?? false, FILTER_VALIDATE_BOOLEAN);
        $maintenanceMessage = $configs['maintenance_message'] ?? null;

        // Only decide when the client reported a usable version — never lock out
        // a client we can't measure.
        $known           = $version > 0;
        $belowFloor      = $known && $minVersion > 0 && $version < $minVersion;
        $behindLatest    = $known && $latestVersion > 0 && $version < $latestVersion;
        $forceUpdate     = $belowFloor || ($updateRequired && $behindLatest);
        $updateAvailable = $behindLatest;

        // Branding — every field defaulted so the app always has something usable.
        // `logo` is the raw stored path; the app resolves it via resolveMediaUrl
        // (never hardcode a host server-side — emulator/phone/prod differ).
        $app = [
            'name'          => $configs['app_name'] ?? config('app.name', 'Tempo'),
            'description'   => $configs['app_description'] ?? '',
            'logo'          => $configs['app_logo'] ?? null,
            'support_email' => $configs['support_email'] ?? null,
            'support_phone' => $configs['support_phone'] ?? null,
            'privacy_url'   => $configs['privacy_url'] ?? null,
            'terms_url'     => $configs['terms_url'] ?? null,
        ];

        // Colors: return the admin override or null. Null lets the app fall back
        // to its own built-in palette, so each build keeps its current look until
        // an admin actually picks a color.
        $color = fn(string $key) => ($configs[$key] ?? '') !== '' ? $configs[$key] : null;
        $theme = [
            'primary'        => $color('theme_primary'),
            'accent'         => $color('theme_accent'),
            'bg_dark'        => $color('theme_bg_dark'),
            'bg_gradient_1'  => $color('theme_bg_gradient_1'),
            'bg_gradient_2'  => $color('theme_bg_gradient_2'),
            'bg_gradient_3'  => $color('theme_bg_gradient_3'),
            'card_bg'        => $color('theme_card_bg'),
            'card_border'    => $color('theme_card_border'),
            'text_primary'   => $color('theme_text_primary'),
            'text_secondary' => $color('theme_text_secondary'),
        ];

        return Common::apiResponse(true, '', [
            'platform'            => $platform,
            'maintenance'         => $maintenance,
            'maintenance_message' => $maintenanceMessage,
            'force_update'        => $forceUpdate,
            'update_available'    => $updateAvailable,
            'min_version'         => $minVersion,
            'latest_version'      => $latestVersion,
            'store_url'           => $storeUrl,
            'app'                 => $app,
            'theme'               => $theme,
        ]);
    }
}
