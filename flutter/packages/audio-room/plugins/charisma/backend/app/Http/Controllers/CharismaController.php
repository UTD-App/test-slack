<?php

namespace App\Http\Controllers;

use App\Helpers\Common;
use App\Models\CharismaLevel;
use App\Models\CharismaRoomData;
use App\Models\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class CharismaController extends Controller
{
    public function levels(): JsonResponse
    {
        $levels = Cache::rememberForever('charisma_levels', function () {
            return CharismaLevel::orderBy('level')->get(['level', 'points', 'image']);
        });

        return Common::apiResponse(true, '', $levels);
    }

    public function roomCharisma(int $roomId): JsonResponse
    {
        $data = CharismaRoomData::where('room_id', $roomId)
            ->orderByDesc('total')
            ->get(['user_id', 'total']);

        $result = $data->values()->map(function ($item, $index) {
            return [
                'user_id' => $item->user_id,
                'total' => (string) $item->total,
                'position' => $index,
            ];
        });

        return Common::apiResponse(true, '', $result);
    }

    public function status(int $roomId): JsonResponse
    {
        $room = Room::find($roomId);
        if (!$room) {
            return Common::apiResponse(false, 'Room not found', null, 404);
        }

        return Common::apiResponse(true, '', [
            'charisma_status' => (bool) $room->charizma_status,
        ]);
    }

    public function changeStatus(Request $request): JsonResponse
    {
        $request->validate(['room_id' => 'required|integer']);

        $room = Room::find($request->room_id);
        if (!$room) {
            return Common::apiResponse(false, 'Room not found', null, 404);
        }

        $room->charizma_status = !$room->charizma_status;
        $room->charizma_timestamp = $room->charizma_status ? time() : null;
        $room->save();

        return Common::apiResponse(true, '', [
            'charisma_status' => $room->charizma_status,
        ]);
    }

    public function reset(Request $request): JsonResponse
    {
        $request->validate(['room_id' => 'required|integer']);

        CharismaRoomData::where('room_id', $request->room_id)
            ->update(['total' => 0]);

        return Common::apiResponse(true, 'Charisma reset successfully');
    }
}
