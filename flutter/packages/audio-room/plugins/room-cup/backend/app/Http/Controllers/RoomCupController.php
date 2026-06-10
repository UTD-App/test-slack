<?php

namespace App\Http\Controllers;

use App\Helpers\Common;
use App\Models\RoomCupTarget;
use Illuminate\Http\JsonResponse;

class RoomCupController extends Controller
{
    public function myReward(int $roomId): JsonResponse
    {
        $userId = auth()->id();

        $targets = RoomCupTarget::active()
            ->with('rewards')
            ->get();

        return Common::apiResponse(true, '', [
            'room_id' => $roomId,
            'user_id' => $userId,
            'targets' => $targets,
        ]);
    }

    public function history(int $roomId): JsonResponse
    {
        $targets = RoomCupTarget::with('rewards')
            ->latest()
            ->get();

        return Common::apiResponse(true, '', [
            'room_id' => $roomId,
            'targets' => $targets,
        ]);
    }

    public function cupTarget(): JsonResponse
    {
        $targets = RoomCupTarget::active()
            ->with('rewards')
            ->get();

        return Common::apiResponse(true, '', $targets);
    }
}
