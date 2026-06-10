<?php

namespace App\Http\Controllers;

use App\Helpers\Common;
use App\Models\Room;
use App\Models\RoomAdministrator;
use App\Models\RoomBlacklist;
use App\Models\RoomVisitor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RoomAdminController extends Controller
{
    public function index(int $roomId): JsonResponse
    {
        $admins = RoomAdministrator::with(['user.profile', 'user.country'])
            ->where('room_id', $roomId)
            ->get()
            ->map(function ($admin) {
                $user = $admin->user;
                return [
                    'id' => $user->id,
                    'name' => $user->profile->name ?? $user->name ?? '',
                    'avatar' => $user->profile->avatar ?? null,
                    'country_flag' => $user->country->flag ?? null,
                    'assigned_at' => $admin->assigned_at,
                ];
            });

        return Common::apiResponse(true, '', $admins);
    }

    public function store(Request $request, int $roomId): JsonResponse
    {
        $room = Room::findOrFail($roomId);

        if (!$room->isOwner(Auth::id())) {
            return Common::apiResponse(false, 'Only room owner can add admins', null, 403);
        }

        $request->validate(['user_id' => 'required|integer|exists:users,id']);
        $userId = $request->user_id;

        if ($room->isOwner($userId)) {
            return Common::apiResponse(false, 'Cannot add owner as admin', null, 422);
        }

        if ($room->isAdmin($userId)) {
            return Common::apiResponse(false, 'User is already admin', null, 422);
        }

        $adminCount = $room->administrators()->count();
        if ($adminCount >= $room->max_admin) {
            return Common::apiResponse(false, 'Maximum admins reached', null, 422);
        }

        $isVisitor = RoomVisitor::where('room_id', $roomId)
            ->where('user_id', $userId)
            ->exists();

        if (!$isVisitor) {
            return Common::apiResponse(false, 'User must be in the room', null, 422);
        }

        RoomAdministrator::create([
            'room_id' => $roomId,
            'user_id' => $userId,
            'assigned_by' => Auth::id(),
            'assigned_at' => now(),
        ]);

        return Common::apiResponse(true, 'Admin added', null, 201);
    }

    public function destroy(int $roomId, int $userId): JsonResponse
    {
        $room = Room::findOrFail($roomId);

        if (!$room->isOwner(Auth::id())) {
            return Common::apiResponse(false, 'Only room owner can remove admins', null, 403);
        }

        RoomAdministrator::where('room_id', $roomId)
            ->where('user_id', $userId)
            ->delete();

        return Common::apiResponse(true, 'Admin removed');
    }

    public function blacklist(int $roomId): JsonResponse
    {
        $bans = RoomBlacklist::with(['user.profile', 'user.country'])
            ->where('room_id', $roomId)
            ->valid()
            ->get()
            ->map(function ($ban) {
                $user = $ban->user;
                return [
                    'id' => $user->id,
                    'name' => $user->profile->name ?? $user->name ?? '',
                    'avatar' => $user->profile->avatar ?? null,
                    'country_flag' => $user->country->flag ?? null,
                    'banned_at' => $ban->banned_at,
                    'expires_at' => $ban->expires_at,
                    'remaining_seconds' => $ban->getTimeRemaining(),
                    'reason' => $ban->reason,
                ];
            });

        return Common::apiResponse(true, '', $bans);
    }

    public function kick(Request $request, int $roomId): JsonResponse
    {
        $room = Room::findOrFail($roomId);

        if (!$room->isOwnerOrAdmin(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'minutes' => 'nullable|integer|min:1',
        ]);

        $userId = $request->user_id;
        $minutes = $request->integer('minutes', 5);

        if ($room->isOwner($userId)) {
            return Common::apiResponse(false, 'Cannot kick room owner', null, 422);
        }

        $durationSeconds = $minutes * 60;

        RoomBlacklist::updateOrCreate(
            ['room_id' => $roomId, 'user_id' => $userId],
            [
                'banned_by' => Auth::id(),
                'banned_at' => now(),
                'duration_seconds' => $durationSeconds,
                'expires_at' => now()->addSeconds($durationSeconds),
                'reason' => 'Kicked from room',
                'is_active' => true,
            ]
        );

        RoomVisitor::where('room_id', $roomId)
            ->where('user_id', $userId)
            ->delete();

        return Common::apiResponse(true, 'User kicked');
    }

    public function ban(Request $request, int $roomId): JsonResponse
    {
        $room = Room::findOrFail($roomId);

        if (!$room->isOwnerOrAdmin(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $request->validate([
            'user_id' => 'required|integer|exists:users,id',
            'duration_seconds' => 'nullable|integer|min:60',
            'reason' => 'nullable|string|max:200',
        ]);

        $userId = $request->user_id;

        if ($room->isOwner($userId)) {
            return Common::apiResponse(false, 'Cannot ban room owner', null, 422);
        }

        $durationSeconds = $request->duration_seconds;
        $expiresAt = $durationSeconds ? now()->addSeconds($durationSeconds) : null;

        RoomBlacklist::updateOrCreate(
            ['room_id' => $roomId, 'user_id' => $userId],
            [
                'banned_by' => Auth::id(),
                'banned_at' => now(),
                'duration_seconds' => $durationSeconds,
                'expires_at' => $expiresAt,
                'reason' => $request->reason,
                'is_active' => true,
            ]
        );

        RoomVisitor::where('room_id', $roomId)
            ->where('user_id', $userId)
            ->delete();

        return Common::apiResponse(true, 'User banned');
    }

    public function unban(int $roomId, int $userId): JsonResponse
    {
        $room = Room::findOrFail($roomId);

        if (!$room->isOwnerOrAdmin(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        RoomBlacklist::where('room_id', $roomId)
            ->where('user_id', $userId)
            ->update(['is_active' => false]);

        return Common::apiResponse(true, 'User unbanned');
    }

    public function checkRole(int $roomId): JsonResponse
    {
        $room = Room::findOrFail($roomId);
        $userId = Auth::id();

        $ban = RoomBlacklist::where('room_id', $roomId)
            ->where('user_id', $userId)
            ->valid()
            ->first();

        return Common::apiResponse(true, '', [
            'is_owner' => $room->isOwner($userId),
            'is_admin' => $room->isAdmin($userId),
            'is_visitor' => RoomVisitor::where('room_id', $roomId)->where('user_id', $userId)->exists(),
            'is_banned' => $ban !== null,
            'ban_expires_at' => $ban?->expires_at,
        ]);
    }
}
