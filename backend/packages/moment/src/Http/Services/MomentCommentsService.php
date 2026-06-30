<?php

namespace Utd\Moment\Http\Services;

use App\Models\User;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentComment;

class MomentCommentsService
{
    public function add($data, Moment $moment, User $user)
    {
        $moment->comments()->create([
            'user_id' => $user->id,
            'comment' => $data['comment'],
        ]);

        return true;
    }

    public function delete($comment_id, Moment $moment)
    {
        $commint = MomentComment::find($comment_id);
        if (! $commint) {
            return 'false';
        }

        // Remove this comment's replies too (otherwise the parent_id FK nulls them
        // out and they'd resurface as top-level). Comment reactions cascade via FK.
        MomentComment::where('parent_id', $comment_id)->delete();
        $moment->comments()->where('moment_user_comments.id', $comment_id)->delete();
    }

    /**
     * Facebook-style reaction on a comment (exclusive — one per user):
     *  - same type again → remove it (toggle off) → 'removed'
     *  - different type   → switch to the new type → 'updated'
     *  - none yet         → add it                 → 'reacted'
     */
    public function reactToComment(MomentComment $comment, User $user, string $type): string
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

    public function showComments($moment)
    {
        $userSelect = function ($query) {
            $query->select(['id', 'uuid', 'name', 'avatar'])->with('profile:id,user_id,avatar');
        };

        // Minimal columns for the reaction summary (count / my_reaction / breakdown)
        // computed in the resource — kept tiny so it stays cheap per comment.
        $likesSelect = fn ($query) => $query->select(['id', 'comment_id', 'user_id', 'reaction_type']);

        // Only top-level comments are paginated; each carries its one level of
        // replies (oldest-first) plus reactions for both itself and its replies.
        return $moment->comments()
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
