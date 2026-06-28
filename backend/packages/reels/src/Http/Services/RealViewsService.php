<?php

namespace Utd\Reels\Http\Services;

use Utd\Reels\Entities\Real;

class RealViewsService extends ReelsBaseModelService
{
    public function __construct(Real $model)
    {
        parent::__construct($model);
    }

    /**
     * Record a view as an atomic increment of the denormalized `view_num` counter.
     *
     * At 5k–10k concurrent viewers a row-per-play insert would hammer
     * real_user_views (unbounded growth + write storm); a single counter UPDATE
     * scales instead. views_count now reads reals.view_num. Returns false when the
     * reel doesn't exist (0 rows affected).
     */
    public function add(int $realId): bool
    {
        return Real::whereKey($realId)->increment('view_num') > 0;
    }

    public function delete($view_id, Real $real)
    {
        // NOTE: Eagle's copy referenced likes() here (copy-paste bug) — fixed to views().
        $real->views()->where('id', $view_id)->delete();
    }

    public function showViews($real)
    {
        return $real->views()->with([
            'user' => function ($query) {
                $query->select(['id', 'name', 'uuid', 'avatar', 'gender'])->with('profile:id,user_id,avatar,birthday');
            },
        ])->orderByDesc('id')->paginate(10);
    }
}
