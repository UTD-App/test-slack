<?php

namespace Utd\Reels\Http\Controllers;

use App\Helpers\Common;
use Illuminate\Routing\Controller;
use Utd\Reels\Http\Services\RealViewsService;

class RealsUserViewsController extends Controller
{
    public function __construct(protected RealViewsService $realViewsService) {}

    public function store($real_id)
    {
        // Atomic counter increment (no model load, no row insert) — survives the
        // view write storm at high concurrency. False => reel doesn't exist.
        if (! $this->realViewsService->add((int) $real_id)) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 402);
        }

        return Common::apiResponse(1, __('reels::messages.success'), [], 200);
    }
}
