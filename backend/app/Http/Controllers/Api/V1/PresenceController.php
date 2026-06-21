<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

/**
 * Online-status lookup for a batch of users (e.g. a chat/follow list). Presence
 * itself is maintained by the UpdateLastSeen middleware which bumps `online_time`
 * on authenticated requests; here we just read it.
 *
 * POST /api/v1/users/online-status  { "ids": [1,2,3] }
 *   -> { status, data: { "1": {is_online, last_seen}, ... } }
 */
class PresenceController extends Controller
{
    public function onlineStatus(Request $request)
    {
        $ids = collect((array) $request->input('ids', []))
            ->map(fn ($id) => (int) $id)
            ->filter()
            ->unique()
            ->take(200)
            ->values();

        $data = User::whereIn('id', $ids)
            ->get(['id', 'online_time'])
            ->mapWithKeys(fn (User $u) => [$u->id => [
                'is_online' => $u->isOnline(),
                'last_seen' => $u->online_time?->toIso8601String(),
            ]])
            ->all();

        return Common::apiResponse(true, '', $data);
    }
}
