<?php

namespace Utd\Moment\Http\Repositories;

use App\Contracts\FollowProvider;
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
        return Moment::where('user_id', $userId)
            ->whereHas('user')
            ->likeExists($userId)
            ->withUser()
            ->with('images')
            ->withCount(['likes', 'comments'])
            ->orderBy('created_at', 'desc')
            ->paginate(10);
    }

    public function getLikedMoments($userId, $page)
    {
        return MomentLikes::with([
            'moment' => function ($query) use ($userId) {
                $query->likeExists($userId)
                    ->withUser()
                    ->with('images')
                    ->withCount(['likes', 'comments']);
            },
        ])
            ->where('user_id', $userId)
            ->orderByDesc('id')
            ->paginate(10);
    }

    public function getAllMoments($userId, $page)
    {
        return $this->feedQuery($userId)
            ->feedOrder($userId)
            ->paginate(10);
    }

    public function getNewMoments($userId)
    {
        return $this->feedQuery($userId)
            ->feedOrder($userId)
            ->paginate(10);
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

        return $query->feedOrder($userId)->paginate(10);
    }

    public function momentUserFollow($userId)
    {
        return $this->getFollowedMoments($userId, null);
    }
}
