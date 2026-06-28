<?php

namespace Utd\Reels\Http\Services;

use App\Models\User;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealUserComment;

class RealCommentsService
{
    /**
     * Create a comment or (when $parentId is set) a one-level reply. Keeps the
     * denormalized counter in step — replies count toward comment_num too, so the
     * feed's comment count matches the total rows.
     */
    public function add($data, Real $real, User $user, ?int $parentId = null)
    {
        $real->comments()->create([
            'user_id'   => $user->id,
            'comment'   => $data['comment'],
            'parent_id' => $parentId,
        ]);
        $real->increment('comment_num');

        return true;
    }

    public function delete($comment_id, Real $real)
    {
        $comment = RealUserComment::find($comment_id);
        if (! $comment) {
            return false;
        }

        // A top-level comment also takes its replies. Decrement comment_num by the
        // number actually removed (the comment + any replies). Comment reactions
        // cascade away via FK.
        $replyCount = RealUserComment::where('parent_id', $comment_id)->count();
        RealUserComment::where('parent_id', $comment_id)->delete();

        if ($real->comments()->where('real_user_comments.id', $comment_id)->delete()) {
            $removed = 1 + $replyCount;
            Real::whereKey($real->id)->where('comment_num', '>', 0)
                ->decrement('comment_num', $removed);
            // Never let the counter dip below zero (clamp after the bulk decrement).
            Real::whereKey($real->id)->where('comment_num', '<', 0)->update(['comment_num' => 0]);
        }
    }

    /**
     * Facebook-style reaction on a comment (exclusive — one per user):
     *  - same type again → remove it (toggle off) → 'removed'
     *  - different type   → switch to the new type → 'updated'
     *  - none yet         → add it                 → 'reacted'
     */
    public function reactToComment(RealUserComment $comment, User $user, string $type): string
    {
        $existing = $comment->likes()->where('user_id', $user->id)->first();

        if ($existing) {
            if ($existing->reaction_type === $type) {
                $existing->delete();

                return 'removed';
            }

            $existing->update(['reaction_type' => $type]);

            return 'updated';
        }

        $comment->likes()->create(['user_id' => $user->id, 'reaction_type' => $type]);

        return 'reacted';
    }

    public function showComments($real)
    {
        $userSelect = function ($query) {
            $query->select(['id', 'uuid', 'name', 'avatar', 'gender'])->with('profile:id,user_id,avatar,birthday');
        };

        // Minimal columns for the reaction summary (count / my_reaction / breakdown)
        // computed in the resource — kept tiny so it stays cheap per comment.
        $likesSelect = fn ($query) => $query->select(['id', 'comment_id', 'user_id', 'reaction_type']);

        // Only top-level comments are paginated; each carries its one level of
        // replies (oldest-first) plus reactions for both itself and its replies.
        return $real->comments()
            ->whereNull('parent_id')
            ->has('user')
            ->with([
                'user' => $userSelect,
                'likes' => $likesSelect,
                'replies' => fn ($query) => $query->has('user')
                    ->with(['user' => $userSelect, 'likes' => $likesSelect])
                    ->orderBy('id'),
            ])->orderByDesc('id')->paginate(10);
    }
}
