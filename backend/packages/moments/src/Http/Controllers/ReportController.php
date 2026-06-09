<?php

namespace Utd\Moment\Http\Controllers;

use App\Helpers\Common;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\ReportMoment;

class ReportController extends Controller
{
    public function store(Request $request, $momentId)
    {
        $userId = Auth::id();

        if (! $request['description']) {
            return Common::apiResponse(false, __('moment::messages.report_need_description'));
        }
        if (! $request['type']) {
            return Common::apiResponse(false, __('moment::messages.report_need_type'));
        }

        $moment = Moment::find($momentId);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 402);
        }

        $reportedId = $moment->user_id;

        $alreadyReported = ReportMoment::where('moment_id', $momentId)
            ->where('Reported_id', $reportedId)
            ->where('Reporter_id', $userId)
            ->first();
        if ($alreadyReported) {
            return Common::apiResponse(0, __('moment::messages.already_reported'), [], 402);
        }

        $user = User::find($reportedId);
        if (! $user) {
            return Common::apiResponse(0, __('moment::messages.user_not_found'), [], 402);
        }

        ReportMoment::create([
            'description' => $request['description'],
            'type'        => $request['type'],
            'moment_id'   => $momentId,
            'Reporter_id' => $userId,
            'Reported_id' => $user->id,
        ]);

        return Common::apiResponse(1, __('moment::messages.success'), '', 200);
    }
}
