<?php

namespace Utd\Reels\Http\Services;

use App\Models\User;
use Illuminate\Database\QueryException;
use Utd\Reels\Entities\Real;

class RealLikesService extends ReelsBaseModelService
{
    public function __construct(Real $model)
    {
        parent::__construct($model);
    }

    public function add(Real $real, User $user)
    {
        $real->likes()->create(['user_id' => $user->id]);
        $real->increment('like_num');

        return true;
    }

    /**
     * Toggle a like. Returns 'Like' when a like was added (so the controller can
     * notify the owner) or 'un Like' when removed. Notification is the
     * controller's job (was App\Facades\CustomNotification in Eagle).
     *
     * Keeps the denormalized `like_num` counter in step via atomic increment/
     * decrement (the feed reads the counter column, not a withCount subquery).
     */
    public function likeOrUnLike(Real $real, User $user)
    {
        $likeData = $real->likes()->where('user_id', $user->id)->first();

        if ($likeData) {
            $likeData->delete();
            $this->decrementCounter($real);

            return 'un Like';
        }

        $real->likes()->create(['user_id' => $user->id]);
        $real->increment('like_num');

        return 'Like';
    }

    /**
     * Facebook-style reaction (exclusive — one per user per reel):
     *  - same type again → remove it (toggle off) → 'removed'
     *  - different type   → switch to the new type    → 'updated'
     *  - none yet         → add it                     → 'reacted'
     *
     * Keeps the denormalized `like_num` counter in step: a brand-new reaction
     * increments it, a removal decrements it, switching type leaves it alone.
     */
    public function react(Real $real, User $user, string $type)
    {
        $existing = $real->likes()->where('user_id', $user->id)->first();

        if ($existing) {
            if ($existing->reaction_type === $type) {
                $existing->delete();
                $this->decrementCounter($real);

                return 'removed';
            }

            $existing->update(['reaction_type' => $type]);

            return 'updated';
        }

        // The unique(real_id,user_id) index makes this race-safe: if a concurrent
        // request created the like first, the duplicate insert throws and we treat
        // it as already-reacted instead of inflating like_num with a second row.
        try {
            $real->likes()->create(['user_id' => $user->id, 'reaction_type' => $type]);
        } catch (QueryException $e) {
            return 'updated';
        }
        $real->increment('like_num');

        return 'reacted';
    }

    public function delete($like_id, Real $real, ?int $userId = null)
    {
        $query = $real->likes()->where('id', $like_id);

        // Ownership scope: a user may only delete their own like.
        if ($userId !== null) {
            $query->where('user_id', $userId);
        }

        if ($query->delete()) {
            $this->decrementCounter($real);
        }
    }

    /** Decrement like_num atomically without dropping below zero. */
    private function decrementCounter(Real $real): void
    {
        Real::whereKey($real->id)->where('like_num', '>', 0)->decrement('like_num');
    }

    public function showLikes($real)
    {
        return $real->likes()->with([
            'user' => function ($query) {
                $query->select(['id', 'name', 'uuid', 'avatar', 'gender'])->with('profile:id,user_id,avatar,birthday');
            },
        ])->orderByDesc('id')->paginate(10);
    }
}
