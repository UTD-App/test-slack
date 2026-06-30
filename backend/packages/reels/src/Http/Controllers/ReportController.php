<?php

namespace Utd\Reels\Http\Controllers;

use App\Helpers\Common;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\ReportReals;

class ReportController extends Controller
{
    public function store(Request $request, $realId)
    {
        $userId = Auth::id();

        if (! $request['description']) {
            return Common::apiResponse(false, __('reels::messages.report_need_description'));
        }
        if (! $request['type']) {
            return Common::apiResponse(false, __('reels::messages.report_need_type'));
        }
        // Both columns are VARCHAR(255); cap before insert so an over-length
        // value returns a clean error instead of a raw SQL 500.
        if (mb_strlen((string) $request['description']) > 255 || mb_strlen((string) $request['type']) > 255) {
            return Common::apiResponse(false, __('reels::messages.content_too_long'));
        }

        $real = Real::find($realId);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 404);
        }

        $reportedId = $real->user_id;

        $alreadyReported = ReportReals::where('real_id', $realId)
            ->where('Reported_id', $reportedId)
            ->where('Reporter_id', $userId)
            ->first();
        if ($alreadyReported) {
            return Common::apiResponse(0, __('reels::messages.already_reported'), [], 409);
        }

        $user = User::find($reportedId);
        if (! $user) {
            return Common::apiResponse(0, __('reels::messages.user_not_found'), [], 404);
        }

        ReportReals::create([
            'description' => $request['description'],
            'type'        => $request['type'],
            'real_id'     => $realId,
            'Reporter_id' => $userId,
            'Reported_id' => $user->id,
        ]);

        // Surface the report on the admin dashboard (moderation queue).
        if (app()->bound('utd.notifier')) {
            \App\Facades\Notifier::toAdmins(
                'reels.report',
                params: [
                    'name'   => Auth::user()?->name ?? __('reels::messages.someone'),
                    'reason' => (string) $request['type'],
                ],
                data: [
                    'real_id'     => (int) $realId,
                    'reported_id' => (int) $user->id,
                    'reporter_id' => (int) $userId,
                    'description' => (string) $request['description'],
                ],
            );
        }

        return Common::apiResponse(1, __('reels::messages.success'), '', 200);
    }
}
