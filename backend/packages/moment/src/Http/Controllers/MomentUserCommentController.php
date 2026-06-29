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
use Utd\Moment\Entities\ReportMomentComment;
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
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        $paginateComments = $this->momentCommentsService->showComments($moment);

        return Common::apiResponse(1, __('moment::messages.success'), MomentCommmintResource::collection($paginateComments), 200);
    }

    public function store($moment_id, Request $request)
    {
        $moment = Moment::find($moment_id);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        $user = Auth::user();

        // Optional reply target: only accept a parent that belongs to THIS moment
        // (and is itself top-level — replies stay one level deep).
        $parentId = $request->input('parent_id');
        if ($parentId) {
            $parent = MomentCommint::where('id', $parentId)->where('moment_id', $moment_id)->first();
            $parentId = $parent ? ($parent->parent_id ?? $parent->id) : null;
        }

        $created = MomentCommint::create([
            'user_id'   => $user->id,
            'comment'   => $request->comment,
            'moment_id' => $moment_id,
            'parent_id' => $parentId,
        ]);

        if (! $created) {
            return Common::apiResponse(0, __('moment::messages.try_again'));
        }

        $this->notifyOwner($moment, $user, __('moment::messages.notify_commented'));

        return Common::apiResponse(1, __('moment::messages.success'));
    }

    /**
     * Facebook-style reaction on a comment (or reply). Exclusive — sending the
     * same type again removes it. Body: { reaction_type }.
     */
    public function react($moment_id, $id, Request $request)
    {
        $moment = Moment::find($moment_id);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        $comment = MomentCommint::where('id', $id)->where('moment_id', $moment_id)->first();
        if (! $comment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        $user = Auth::user();

        $type = (string) $request->input('reaction_type', 'like');
        if (! in_array($type, ['like', 'love', 'haha', 'wow', 'sad', 'angry'], true)) {
            $type = 'like';
        }

        $result = $this->momentCommentsService->reactToComment($comment, $user, $type);

        // Notify the comment's author (not the moment owner) unless they removed
        // the reaction or reacted to their own comment.
        if ($result !== 'removed' && $comment->user_id !== $user->id) {
            $this->notifyUserId($comment->user_id, $user, __('moment::messages.notify_liked'), $moment_id);
        }

        return Common::apiResponse(1, __('moment::messages.success'), [], 200);
    }

    /** Report a comment (or reply). Body: { description, type }. */
    public function report($moment_id, $id, Request $request)
    {
        $moment = Moment::find($moment_id);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        $comment = MomentCommint::where('id', $id)->where('moment_id', $moment_id)->first();
        if (! $comment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        if (! $request->input('description')) {
            return Common::apiResponse(false, __('moment::messages.report_need_description'));
        }
        if (! $request->input('type')) {
            return Common::apiResponse(false, __('moment::messages.report_need_type'));
        }

        $userId = Auth::id();
        $already = ReportMomentComment::where('comment_id', $id)->where('Reporter_id', $userId)->first();
        if ($already) {
            return Common::apiResponse(0, __('moment::messages.already_reported_comment'), [], 409);
        }

        ReportMomentComment::create([
            'comment_id'  => $id,
            'moment_id'   => $moment_id,
            'Reporter_id' => $userId,
            'Reported_id' => $comment->user_id,
            'type'        => $request->input('type'),
            'description' => $request->input('description'),
        ]);

        return Common::apiResponse(1, __('moment::messages.success'), '', 200);
    }

    public function destroy($momentId, $id)
    {
        $moment = Moment::find($momentId);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        $comment = MomentCommint::where('id', $id)->where('moment_id', $momentId)->first();
        if (! $comment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        // Authorization: only the comment's author OR the moment owner may delete.
        $userId = (int) Auth::id();
        if ((int) $comment->user_id !== $userId && (int) $moment->user_id !== $userId) {
            return Common::apiResponse(0, __('moment::messages.not_allowed'), [], 403);
        }

        try {
            $this->momentCommentsService->delete($id, $moment);

            return Common::apiResponse(1, __('moment::messages.success'), [], 200);
        } catch (\Throwable) {
            return Common::apiResponse(0, __('moment::messages.try_again'), [], 422);
        }
    }

    /**
     * NOTE(gap): replaces App\Facades\CustomNotification::momentComment().
     */
    protected function notifyOwner(Moment $moment, $actor, string $body): void
    {
        $this->notifyUserId($moment->user_id, $actor, $body, (int) $moment->id);
    }

    /** Best-effort FCM to a specific user (skips self + when no sender is bound). */
    protected function notifyUserId(?int $userId, $actor, string $body, int $momentId): void
    {
        if (! $userId || $userId === $actor->id || ! app()->bound(NotificationSender::class)) {
            return;
        }

        $recipient = User::find($userId);
        if (! $recipient) {
            return;
        }

        try {
            app(NotificationSender::class)->send(
                $recipient,
                NotificationMessage::make(
                    $actor->name ?? __('moment::messages.someone'),
                    $body,
                    ['type' => 'moment', 'id' => (string) $momentId],
                ),
            );
        } catch (\Throwable) {
            // best-effort
        }
    }
}
