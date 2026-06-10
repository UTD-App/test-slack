<?php

namespace App\Http\Controllers;

use App\Helpers\Common;
use App\Http\Resources\PkResource;
use App\Models\Pk;
use App\Models\Room;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PkController extends Controller
{
    public function showPk(Request $request): JsonResponse
    {
        $user = $request->user();
        $room = $this->findRoom($request->room_id, $request->owner_id);

        if (!$room) {
            return Common::apiResponse(false, 'Room not found');
        }
        if ($user->id != $room->uid) {
            return Common::apiResponse(false, 'Permission denied', null, 403);
        }

        $room->update(['is_show_pk' => true, 'is_pk_custom' => true]);

        return Common::apiResponse(true, 'done', [
            'messageContent' => ['message' => 'showPK'],
        ]);
    }

    public function createPk(Request $request): JsonResponse
    {
        $user = $request->user();
        $room = $this->findRoom($request->room_id, $request->owner_id);

        if (!$room) {
            return Common::apiResponse(false, 'Room not found');
        }
        if ($user->id != $room->uid) {
            return Common::apiResponse(false, 'Permission denied', null, 403);
        }

        $existing = Pk::where('room_id', $room->id)->where('status', 1)->first();
        if ($existing) {
            $existing->update(['status' => 0]);
        }

        $pk = Pk::create([
            'room_id' => $room->id,
            'status' => 1,
            'mics' => $room->microphone ?? '0,0,0,0,0,0,0,0',
            'start_at' => Carbon::now(),
            'end_at' => Carbon::now()->addMinutes($request->input('minutes', 5)),
        ]);

        return Common::apiResponse(true, 'created', [
            'messageContent' => [
                'message' => 'startPK',
                'PkTime' => $request->input('minutes', 5),
                'pk_id' => $pk->id,
            ],
        ], 201);
    }

    public function closePk(Request $request): JsonResponse
    {
        if (!$request->pk_id) {
            return Common::apiResponse(false, 'Missing pk_id', null, 422);
        }

        $pk = Pk::find($request->pk_id);
        if (!$pk) {
            return Common::apiResponse(false, 'PK not found or already closed');
        }

        $winner = ($pk->t1_score > $pk->t2_score)
            ? 1
            : (($pk->t2_score > $pk->t1_score) ? 2 : 0);

        $pk->update(['winner' => $winner, 'status' => 0]);

        return Common::apiResponse(true, 'closed', [
            'messageContent' => [
                'message' => 'closePk',
                'scoreTeam1' => $pk->t1_score,
                'scoreTeam2' => $pk->t2_score,
                'percentagepk_team1' => $pk->t1_per,
                'percentagepk_team2' => $pk->t2_per,
                'winner_Team' => $winner,
            ],
        ]);
    }

    public function hidePk(Request $request): JsonResponse
    {
        $user = $request->user();
        $room = $this->findRoom($request->room_id, $request->owner_id);

        if (!$room) {
            return Common::apiResponse(false, 'Room not found');
        }
        if ($user->id != $room->uid) {
            return Common::apiResponse(false, 'Permission denied', null, 403);
        }

        $room->update(['is_show_pk' => false, 'is_pk_custom' => false]);

        return Common::apiResponse(true, 'done', [
            'messageContent' => ['message' => 'hidePK'],
        ]);
    }

    public function history(int $roomId): JsonResponse
    {
        $room = Room::find($roomId);
        if (!$room) {
            return Common::apiResponse(false, 'Room not found', null, 404);
        }

        $pks = Pk::where('room_id', $room->id)
            ->where('status', 0)
            ->orderByDesc('created_at')
            ->paginate(20);

        return Common::apiResponse(true, '', PkResource::collection($pks));
    }

    private function findRoom(?int $roomId, ?int $ownerId): ?Room
    {
        if ($roomId) {
            return Room::find($roomId);
        }
        if ($ownerId) {
            return Room::where('uid', $ownerId)->where('enable_audio', 1)->first();
        }
        return null;
    }
}
