<?php

namespace App\Http\Controllers;

use App\Helpers\Common;
use App\Http\Resources\BoomPercentageResource;
use App\Http\Resources\RoomBoomLevelResource;
use App\Http\Resources\RoomBoomRuleResource;
use App\Http\Resources\ThemeBoomLevelResource;
use App\Models\BoomPercentage;
use App\Models\RoomBoomLevel;
use App\Models\SuperBoomRule;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class SuperBombController extends Controller
{
    public function levels(int $roomId): JsonResponse
    {
        $tz = getTimezone();
        $today = Carbon::today($tz);

        $levels = RoomBoomLevel::with([
            'roomBoomRewards' => fn ($q) => $q->orderBy('priority'),
            'roomBooms' => fn ($q) => $q
                ->whereHas('totalRoomGift', fn ($sub) => $sub->where('room_id', $roomId))
                ->whereDate('started_at', $today),
        ])->orderBy('level')->get();

        return Common::apiResponse(true, '', RoomBoomLevelResource::collection($levels));
    }

    public function videos(): JsonResponse
    {
        $levels = Cache::remember('boom_levels:videos', 300, function () {
            return RoomBoomLevel::select(['id', 'level', 'video', 'image_type'])
                ->with(['roomBoomRewards' => fn ($q) => $q
                    ->select(['id', 'room_boom_level_id', 'priority', 'target_type', 'target', 'quantity', 'expire_days'])
                    ->orderBy('priority'),
                ])
                ->orderBy('level')
                ->get();
        });

        return Common::apiResponse(true, '', RoomBoomLevelResource::collection($levels));
    }

    public function themes(): JsonResponse
    {
        $levels = RoomBoomLevel::orderBy('level')->get();
        $percentages = BoomPercentage::orderBy('percentage')->get();

        return Common::apiResponse(true, '', [
            'levels' => ThemeBoomLevelResource::collection($levels),
            'progress_animations' => BoomPercentageResource::collection($percentages),
        ]);
    }

    public function rules(): JsonResponse
    {
        $rules = SuperBoomRule::all();

        return Common::apiResponse(true, '', RoomBoomRuleResource::collection($rules));
    }
}
