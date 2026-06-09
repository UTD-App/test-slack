<?php

namespace Utd\Moment\Http\Controllers;

use App\Contracts\NotificationSender;
use App\Helpers\Common;
use App\Models\User;
use App\Support\Notifications\NotificationMessage;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentCommint;
use Utd\Moment\Http\Services\MomentCommentsService;
use Utd\Moment\Http\Services\MomentService;
use Utd\Moment\Transformers\MomentCommmintResource;

class MomentUserCommentController extends Controller
{
    public function __construct(
        protected MomentService $momentsService,
        protected MomentCommentsService $momentCommentsService,
    ) {}

    public function index($moment_id)
    {
        $moment = Moment::find($moment_id);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 402);
        }

        $paginateComments = $this->momentCommentsService->showComments($moment);

        return Common::apiResponse(1, __('moment::messages.success'), MomentCommmintResource::collection($paginateComments), 200);
    }

    public function store($moment_id, Request $request)
    {
        $moment = Moment::find($moment_id);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 402);
        }

        $user = Auth::user();

        $created = MomentCommint::create([
            'user_id'   => $user->id,
            'comment'   => $request->comment,
            'moment_id' => $moment_id,
        ]);

        if (! $created) {
            return Common::apiResponse(0, __('moment::messages.try_again'));
        }

        $this->notifyOwner($moment, $user, __('moment::messages.notify_commented'));

        return Common::apiResponse(1, __('moment::messages.success'));
    }

    public function destroy($momentId, $id)
    {
        $moment = Moment::find($momentId);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 402);
        }

        try {
            $this->momentCommentsService->delete($id, $moment);

            return Common::apiResponse(1, __('moment::messages.success'), [], 200);
        } catch (\Throwable) {
            return Common::apiResponse(0, __('moment::messages.try_again'), [], 402);
        }
    }

    /**
     * NOTE(gap): replaces App\Facades\CustomNotification::momentComment().
     */
    protected function notifyOwner(Moment $moment, $actor, string $body): void
    {
        $owner = User::find($moment->user_id);
        if (! $owner || $owner->id === $actor->id || ! app()->bound(NotificationSender::class)) {
            return;
        }

        try {
            app(NotificationSender::class)->send(
                $owner,
                NotificationMessage::make(
                    $actor->name ?? __('moment::messages.someone'),
                    $body,
                    ['type' => 'moment', 'id' => (string) $moment->id],
                ),
            );
        } catch (\Throwable) {
            // best-effort
        }
    }
}
