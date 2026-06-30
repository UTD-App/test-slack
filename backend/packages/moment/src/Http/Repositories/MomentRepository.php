<?php

namespace Utd\Moment\Http\Repositories;

use App\Contracts\FollowProvider;
use Illuminate\Support\Facades\Auth;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentLikes;
use Utd\Moment\Entities\ReportMoment;

/**
 * Feed ordering mirrors Eagle: not-yet-liked moments float to the top, then
 * recency (see Moment::scopeFeedOrder). The "Following" feeds filter by the
 * social follow graph via the optional App\Contracts\FollowProvider seam; while
 * it is unbound they fall back to the full feed.
 *
 * NOTE(gap): Eagle also eager-loaded `user.chatRoomsAsUser` (Chat package) and
 * aggregated `gifts` counts — those live in packages bound via their own seams.
 */
class MomentRepository
{
    /** Base feed query shared by every feed type (eager-loads + counts + like flag). */
    private function feedQuery($userId)
    {
        return Moment::query()
            ->whereHas('user')
            ->likeExists($userId)
            ->withUser()
            ->with('images')
            ->withCount(['likes', 'comments']);
    }

    /**
     * Batch the viewer's reaction + the per-type breakdown for a whole page of
     * moments — 2 queries total instead of 2 per moment (the old N+1 in
     * MomentResource). Results are stashed on each model as `my_reaction_pre` /
     * `reactions_pre`; MomentResource reads those and only falls back to a
     * per-moment query when they're absent (e.g. the single-moment show endpoint).
     */
    private function hydrateReactions($paginator)
    {
        $moments = $paginator->getCollection();
        $ids = $moments->pluck('id')->all();
        if (empty($ids)) {
            return $paginator;
        }

        $viewer = Auth::id();
        $mine = $viewer
            ? MomentLikes::whereIn('moment_id', $ids)->where('user_id', $viewer)->pluck('reaction_type', 'moment_id')
            : collect();

        $breakdown = [];
        $rows = MomentLikes::whereIn('moment_id', $ids)
            ->selectRaw('moment_id, reaction_type, COUNT(*) as c')
            ->groupBy('moment_id', 'reaction_type')
            ->get();
        foreach ($rows as $r) {
            $breakdown[$r->moment_id][$r->reaction_type] = (int) $r->c;
        }

        foreach ($moments as $m) {
            $m->setAttribute('my_reaction_pre', $mine[$m->id] ?? null);
            $m->setAttribute('reactions_pre', $breakdown[$m->id] ?? []);
        }

        return $paginator;
    }

    public function findReportMomentById($id)
    {
        return ReportMoment::find($id);
    }

    public function deleteReportMoment(ReportMoment $reportMoment)
    {
        return $reportMoment->delete();
    }

    public function findMomentById($id)
    {
        return Moment::find($id);
    }

    public function deleteMoment(Moment $moment)
    {
        return $moment->delete();
    }

    public function getMomentById($id, $userId)
    {
        return Moment::where('id', $id)
            ->likeExists($userId)
            ->withUser()
            ->with('images')
            ->withCount(['likes', 'comments'])
            ->first();
    }

    public function createMoment(array $data)
    {
        return Moment::create($data);
    }

    public function getUserMoments($userId, $page)
    {
        return $this->hydrateReactions(
            Moment::where('user_id', $userId)
                ->whereHas('user')
                ->likeExists($userId)
                ->withUser()
                ->with('images')
                ->withCount(['likes', 'comments'])
                ->orderBy('created_at', 'desc')
                ->paginate(10)
        );
    }

    /**
     * Moments the viewer has liked. Returns Moment models (not MomentLikes rows)
     * so the payload matches MomentResource — same eager-load/count/like-flag
     * shape as the other feeds. Filtered to moments the viewer liked and ordered
     * by most-recently liked first (a correlated subquery on the viewer's like id,
     * which keeps the builder's withCount/withExists selects intact — a join's
     * select('moment.*') would clobber them).
     */
    public function getLikedMoments($userId, $page)
    {
        return $this->hydrateReactions(
            $this->feedQuery($userId)
                ->whereHas('likes', fn ($q) => $q->where('user_id', $userId))
                ->orderByDesc(
                    MomentLikes::select('id')
                        ->whereColumn('moment_user_likes.moment_id', 'moment.id')
                        ->where('user_id', $userId)
                        ->latest('id')
                        ->limit(1)
                )
                ->paginate(10)
        );
    }

    public function getAllMoments($userId, $page)
    {
        return $this->hydrateReactions(
            $this->feedQuery($userId)->feedOrder($userId)->paginate(10)
        );
    }

    public function getNewMoments($userId)
    {
        return $this->hydrateReactions(
            $this->feedQuery($userId)->feedOrder($userId)->paginate(10)
        );
    }

    /**
     * Moments authored by people the viewer follows. Uses the social follow graph
     * via the optional FollowProvider seam; falls back to the full feed when the
     * social package isn't installed (Eagle parity: nothing breaks without follows).
     */
    public function getFollowedMoments($userId, $page)
    {
        $query = $this->feedQuery($userId);

        if (app()->bound(FollowProvider::class)) {
            $followingIds = app(FollowProvider::class)->followingIds((int) $userId);
            $query->whereIn('user_id', $followingIds ?: [0]); // [0] → empty result when following nobody
        }

        return $this->hydrateReactions($query->feedOrder($userId)->paginate(10));
    }

    public function momentUserFollow($userId)
    {
        return $this->getFollowedMoments($userId, null);
    }
}
