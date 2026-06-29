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
use Utd\Moment\Http\Services\MomentLikesService;
use Utd\Moment\Http\Services\MomentService;
use Utd\Moment\Transformers\MomentlikesResource;

class MomentUserLikesController extends Controller
{
    public function __construct(
        protected MomentService $momentsService,
        protected MomentLikesService $momentLikesService,
    ) {}

    public function index($moment_id)
    {
        $moment = Moment::find($moment_id);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        $paginateLikes = $this->momentLikesService->showLikes($moment);

        return Common::apiResponse(1, __('moment::messages.success'), MomentlikesResource::collection($paginateLikes), 200);
    }

    public function store($moment_id, Request $request)
    {
        $user = Auth::user();

        $moment = Moment::find($moment_id);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        // Facebook-style reaction type; defaults to 'like' (back-compat with the
        // old plain-like client that sends no body).
        $type = (string) $request->input('reaction_type', 'like');
        if (! in_array($type, ['like', 'love', 'haha', 'wow', 'sad', 'angry'], true)) {
            $type = 'like';
        }

        $result = $this->momentLikesService->react($moment, $user, $type);

        if ($result !== 'removed') {
            $this->notifyOwner($moment, $user, __('moment::messages.notify_liked'));
        }

        return Common::apiResponse(1, __('moment::messages.success'), [], 200);
    }

    /**
     * Notify the moment owner via the Base NotificationSender contract.
     * NOTE(gap): replaces App\Facades\CustomNotification::likeMoment().
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
