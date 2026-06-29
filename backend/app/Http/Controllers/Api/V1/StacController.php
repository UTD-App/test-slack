<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\Config;
use App\Models\StacScreen;
use Illuminate\Http\Request;

class StacController extends Controller
{
    // GET /api/stac/{name}
    // Returns a single screen JSON by name
    public function show(string $name): \Illuminate\Http\JsonResponse
    {
        $screen = StacScreen::where('name', $name)
            ->where('is_active', true)
            ->first();

        if (!$screen) {
            return Common::apiResponse(false, __('messages.screen_not_found'), null, 404);
        }

        return Common::apiResponse(true, '', [
            'name'    => $screen->name,
            'version' => $screen->version,
            'content' => $screen->content,
        ]);
    }

    // GET /api/stac/{name}/version
    // Returns only version — Flutter checks this before fetching full content
    public function version(string $name): \Illuminate\Http\JsonResponse
    {
        $screen = StacScreen::where('name', $name)
            ->where('is_active', true)
            ->select('name', 'version')
            ->first();

        if (!$screen) {
            return Common::apiResponse(false, __('messages.screen_not_found'), null, 404);
        }

        return Common::apiResponse(true, '', [
            'name'    => $screen->name,
            'version' => $screen->version,
        ]);
    }

    // POST /api/stac/push
    // Called by UTD Stac Panel to push updated screens to client's server
    // Secured by UTD_STAC_KEY stored in configs table
    public function push(Request $request): \Illuminate\Http\JsonResponse
    {
        $stacKey = Config::where('name', 'utd_stac_key')->value('value');

        if (!$stacKey || $request->header('X-Stac-Key') !== $stacKey) {
            return Common::apiResponse(false, __('messages.unauthorized'), null, 401);
        }

        $screens = $request->validate([
            'screens'               => 'required|array',
            'screens.*.name'        => 'required|string',
            'screens.*.package'     => 'required|string',
            'screens.*.version'     => 'required|string',
            'screens.*.content'     => 'required|array',
            'screens.*.is_active'   => 'boolean',
        ])['screens'];

        $pushed = 0;
        foreach ($screens as $screen) {
            StacScreen::updateOrCreate(
                ['name' => $screen['name']],
                [
                    'package'   => $screen['package'],
                    'version'   => $screen['version'],
                    'content'   => $screen['content'],
                    'is_active' => $screen['is_active'] ?? true,
                ]
            );
            $pushed++;
        }

        return Common::apiResponse(true, "{$pushed} screens pushed successfully.", ['pushed' => $pushed]);
    }

    // GET /api/stac
    // Returns all active screens with their versions (for batch version check)
    public function index(): \Illuminate\Http\JsonResponse
    {
        $screens = StacScreen::where('is_active', true)
            ->select('name', 'package', 'version')
            ->get();

        return Common::apiResponse(true, '', $screens);
    }
}
