<?php

namespace Utd\Reels\Http\Controllers;

use App\Facades\Notifier;
use App\Helpers\Common;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealUserComment;
use Utd\Reels\Entities\ReportRealComment;
use Utd\Reels\Http\Services\RealCommentsService;
use Utd\Reels\Transformers\RealCommentsResource;

class RealsUserCommentController extends Controller
{
    public function __construct(protected RealCommentsService $realCommentsService) {}

    public function index($real_id)
    {
        $real = Real::find($real_id);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 404);
        }

        $comments = $this->realCommentsService->showComments($real);

        return Common::apiResponse(1, __('reels::messages.success'), RealCommentsResource::collection($comments), 200);
    }

    public function store($real_id, Request $request)
    {
        $real = Real::find($real_id);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 404);
        }

        $comment = trim((string) $request->input('comment'));
        if ($comment === '') {
            return Common::apiResponse(0, __('reels::messages.empty_content'));
        }
        if (mb_strlen($comment) > 255) {
            return Common::apiResponse(0, __('reels::messages.content_too_long'));
        }

        $user = Auth::user();

        // Optional reply target: only accept a parent that belongs to THIS reel
        // (and is itself top-level — replies stay one level deep).
        $parentId = $request->input('parent_id');
        if ($parentId) {
            $parent = RealUserComment::where('id', $parentId)->where('real_id', $real_id)->first();
            $parentId = $parent ? ($parent->parent_id ?? $parent->id) : null;
        }

        $created = $this->realCommentsService->add(['comment' => $comment], $real, $user, $parentId);
        if (! $created) {
            return Common::apiResponse(0, __('reels::messages.try_again'));
        }

        $this->notifyOwner($real, $user, 'reels.comment');

        return Common::apiResponse(1, __('reels::messages.success'));
    }

    /**
     * Facebook-style reaction on a comment (or reply). Exclusive — sending the
     * same type again removes it. Body: { reaction_type }.
     */
    public function react($real_id, $id, Request $request)
    {
        $real = Real::find($real_id);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 404);
        }

        $comment = RealUserComment::where('id', $id)->where('real_id', $real_id)->first();
        if (! $comment) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 404);
        }

        $user = Auth::user();

        $type = (string) $request->input('reaction_type', 'like');
        if (! in_array($type, ['like', 'love', 'haha', 'wow', 'sad', 'angry'], true)) {
            $type = 'like';
        }

        $result = $this->realCommentsService->reactToComment($comment, $user, $type);

        // Notify the comment's author (not the reel owner) unless they removed the
        // reaction or reacted to their own comment.
        if ($result !== 'removed' && (int) $comment->user_id !== (int) $user->id) {
            $this->notifyUser($comment->user_id, $real, $user, 'reels.comment.like');
        }

        return Common::apiResponse(1, __('reels::messages.success'), [], 200);
    }

    /** Report a comment (or reply). Body: { description, type }. */
    public function report($real_id, $id, Request $request)
    {
        $real = Real::find($real_id);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 404);
        }

        $comment = RealUserComment::where('id', $id)->where('real_id', $real_id)->first();
        if (! $comment) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 404);
        }

        if (! $request->input('description')) {
            return Common::apiResponse(false, __('reels::messages.report_need_description'));
        }
        if (! $request->input('type')) {
            return Common::apiResponse(false, __('reels::messages.report_need_type'));
        }

        $userId = Auth::id();
        $already = ReportRealComment::where('comment_id', $id)->where('Reporter_id', $userId)->first();
        if ($already) {
            return Common::apiResponse(0, __('reels::messages.already_reported_comment'), [], 409);
        }

        ReportRealComment::create([
            'comment_id'  => $id,
            'real_id'     => $real_id,
            'Reporter_id' => $userId,
            'Reported_id' => $comment->user_id,
            'type'        => $request->input('type'),
            'description' => $request->input('description'),
        ]);

        return Common::apiResponse(1, __('reels::messages.success'), '', 200);
    }

    public function destroy($real_id, $id)
    {
        $real = Real::find($real_id);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 404);
        }

        $comment = RealUserComment::where('id', $id)->where('real_id', $real_id)->first();
        if (! $comment) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 404);
        }

        // Authorization: only the comment's author OR the reel owner may delete.
        $userId = (int) Auth::id();
        if ((int) $comment->user_id !== $userId && (int) $real->user_id !== $userId) {
            return Common::apiResponse(0, __('reels::messages.not_allowed'), [], 403);
        }

        try {
            $this->realCommentsService->delete($id, $real);

            return Common::apiResponse(1, __('reels::messages.success'), [], 200);
        } catch (\Throwable) {
            return Common::apiResponse(0, __('reels::messages.try_again'), [], 422);
        }
    }

    /**
     * Notify the reel owner via the high-level Notifier (in-app feed + push +
     * recipient-locale text + preferences). No-op if the notification system
     * isn't installed. Replaces App\Facades\CustomNotification::CommentReal().
     */
    protected function notifyOwner(Real $real, $actor, string $typeKey): void
    {
        $this->notifyUser($real->user_id, $real, $actor, $typeKey);
    }

    /** Best-effort notification to a specific user (skips self + when unbound). */
    protected function notifyUser(?int $userId, Real $real, $actor, string $typeKey): void
    {
        if (! $userId || (int) $userId === (int) $actor->id || ! app()->bound('utd.notifier')) {
            return;
        }

        $recipient = User::find($userId);
        if (! $recipient) {
            return;
        }

        Notifier::send(
            $recipient,
            $typeKey,
            params: ['name' => $actor->name ?? __('reels::messages.someone')],
            data: ['reel_id' => $real->id],
            actor: $actor,
        );
    }
}
