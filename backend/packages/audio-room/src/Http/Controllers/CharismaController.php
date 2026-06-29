<?php

namespace Utd\AudioRoom\Http\Controllers;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use Utd\AudioRoom\Entities\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Utd\AudioRoom\Models\CharismaLevel;
use Utd\AudioRoom\Models\CharismaRoomData;

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
        $request->validate([
            'room_id' => 'required|integer',
            'status' => 'required|boolean',
        ]);

        $room = Room::find($request->room_id);
        if (!$room) {
            return Common::apiResponse(false, 'Room not found', null, 404);
        }

        if (!$room->isOwnerOrAdmin(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $room->charizma_status = $request->status;
        $room->charizma_timestamp = $request->status ? time() : null;
        $room->save();

        return Common::apiResponse(true, '', [
            'charisma_status' => $room->charizma_status,
        ]);
    }

    public function reset(Request $request): JsonResponse
    {
        $request->validate(['room_id' => 'required|integer']);

        $room = Room::find($request->room_id);
        if (!$room) {
            return Common::apiResponse(false, 'Room not found', null, 404);
        }

        if (!$room->isOwnerOrAdmin(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        CharismaRoomData::where('room_id', $request->room_id)
            ->update(['total' => 0]);

        return Common::apiResponse(true, 'Charisma reset successfully');
    }
}
