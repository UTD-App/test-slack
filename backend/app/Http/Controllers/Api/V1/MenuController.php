<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Services\MenuService;

class MenuController extends Controller
{
    public function __construct(protected MenuService $menu)
    {
    }

    // GET /api/menu/version — cheap version check (mirrors stac/translations)
    public function version(): \Illuminate\Http\JsonResponse
    {
        return Common::apiResponse(true, '', ['version' => $this->menu->version()]);
    }

    // GET /api/menu — full menu config for the app (enabled packages, ordered)
    public function index(): \Illuminate\Http\JsonResponse
    {
        return Common::apiResponse(true, '', [
            'version' => $this->menu->version(),
            'items'   => $this->menu->buildAppPayload(),
        ]);
    }
}
