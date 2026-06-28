<?php

namespace Utd\Reels\Http\Repositories;

use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Pagination\Paginator;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealUserLike;
use Utd\Reels\Entities\ReportReals;

/**
 * NOTE(gap): Eagle's feed mixed interest-matched, not-interested and liked reels
 * with per-user random seeds (`real_type`) and Follow/Interest scopes. Those live
 * in packages/columns that aren't in the Base, so the feed here is simplified to
 * a chronological/seeded-shuffle list (mirrors the Moment package). See NOTES_GAPS.md.
 *
 * Performance: like/comment/view counts are read from the denormalized
 * like_num/comment_num/view_num columns (maintained by the like/comment/view
 * services) — NOT per-row withCount() subqueries. The seeded feed shares one
 * briefly-cached recent window across all users and only hydrates the current
 * page's 10 reels, so 5k–10k concurrent viewers don't each re-read+sort 150 rows.
 */
class ReelsRepository
{
    private const PER_PAGE = 10;

    /** How many recent reels form the shuffled "deck" arranged per seed. */
    private const FEED_WINDOW = 150;

    /** How long the shared recent-reels window is cached (seconds). */
    private const WINDOW_TTL = 60;

    /** Cache key for the shared recent-reels window. */
    private const WINDOW_KEY = 'reels:feed:window';

    /**
     * Batch the viewer's reaction + the per-type breakdown for a whole page of
     * reels — 2 queries total instead of 2 per reel (the N+1 in RealsResource).
     * Results are stashed on each model as `my_reaction_pre` / `reactions_pre`;
     * RealsResource reads those and only falls back to a per-reel query when
     * they're absent (e.g. the single-reel show endpoint).
     */
    private function hydrateReactions($paginator)
    {
        $reels = $paginator->getCollection();
        $ids = $reels->pluck('id')->all();
        if (empty($ids)) {
            return $paginator;
        }

        $viewer = Auth::id();
        $mine = $viewer
            ? RealUserLike::whereIn('real_id', $ids)->where('user_id', $viewer)->pluck('reaction_type', 'real_id')
            : collect();

        $breakdown = [];
        $rows = RealUserLike::whereIn('real_id', $ids)
            ->selectRaw('real_id, reaction_type, COUNT(*) as c')
            ->groupBy('real_id', 'reaction_type')
            ->get();
        foreach ($rows as $r) {
            $breakdown[$r->real_id][$r->reaction_type] = (int) $r->c;
        }

        foreach ($reels as $reel) {
            $reel->setAttribute('my_reaction_pre', $mine[$reel->id] ?? null);
            $reel->setAttribute('reactions_pre', $breakdown[$reel->id] ?? []);
        }

        return $paginator;
    }

    public function findReportReelById($id)
    {
        return ReportReals::find($id);
    }

    public function deleteReportReel(ReportReals $report)
    {
        return $report->delete();
    }

    public function findReelById($id)
    {
        return Real::find($id);
    }

    public function deleteReel(Real $real)
    {
        return $real->delete();
    }

    public function getReelById($id, $userId)
    {
        return Real::where('id', $id)
            ->likeExists($userId)
            ->withUser()
            ->first();
    }

    public function getUserReals($userId, $currentUserId)
    {
        return $this->hydrateReactions(
            Real::where('user_id', $userId)
                ->whereHas('user')
                ->likeExists($currentUserId)
                ->withUser()
                ->orderByDesc('id')
                ->simplePaginate(self::PER_PAGE)
        );
    }

    public function getAllReels($userId, ?int $seed = null)
    {
        // No seed → plain chronological feed. simplePaginate avoids the COUNT(*)
        // that paginate() runs every request (the client only checks for a
        // non-empty page, never the total). Counts come from the *_num columns.
        if ($seed === null) {
            return $this->hydrateReactions(
                Real::query()
                    ->whereHas('user')
                    ->likeExists($userId)
                    ->withUser()
                    ->orderByDesc('id')
                    ->simplePaginate(self::PER_PAGE)
            );
        }

        // Deterministic per-seed shuffle of the shared recent window. Slicing by
        // page keeps pages disjoint and stable for a given seed; a fresh seed on
        // the next refresh produces a brand-new order. This is a single O(n) pass
        // over ~150 lightweight {id,url} objects — far cheaper per request than
        // the old layered round-robin arrangement (multiple Collection passes),
        // which matters at high concurrency, and is visually identical for real
        // uploads (all-distinct video URLs). The window is shared across users +
        // cached for WINDOW_TTL, and only the page's 10 reels are hydrated.
        $ordered = $this->recentWindow()->shuffle($seed);

        $page    = max(1, Paginator::resolveCurrentPage());
        $pageIds = $ordered->slice(($page - 1) * self::PER_PAGE, self::PER_PAGE)
            ->pluck('id')
            ->all();

        return $this->hydrateReactions(new LengthAwarePaginator(
            $this->hydrateReels($pageIds, $userId),
            $ordered->count(),
            self::PER_PAGE,
            $page,
            ['path' => Paginator::resolveCurrentPath()]
        ));
    }

    /**
     * The recent feed window as lightweight {id, url} objects, shared across all
     * users and cached for a short TTL so concurrent viewers don't each run the
     * 150-row scan. whereHas('user') drops reels by soft-deleted authors.
     */
    private function recentWindow(): Collection
    {
        return Cache::remember(self::WINDOW_KEY, self::WINDOW_TTL, function () {
            return Real::query()
                ->whereHas('user')
                ->orderByDesc('id')
                ->limit(self::FEED_WINDOW)
                ->get(['id', 'url'])
                ->map(fn (Real $r) => (object) ['id' => $r->id, 'url' => $r->url]);
        });
    }

    /**
     * Hydrate one page of reel ids with author + per-user like flag, preserving
     * the arranged order. Counts come from the denormalized columns (no withCount).
     */
    private function hydrateReels(array $ids, $userId): Collection
    {
        if (empty($ids)) {
            return collect();
        }

        $byId = Real::whereIn('id', $ids)
            ->likeExists($userId)
            ->withUser()
            ->get()
            ->keyBy('id');

        return collect($ids)
            ->map(fn ($id) => $byId->get($id))
            ->filter()
            ->values();
    }

    public function getNewReels($userId, ?int $seed = null)
    {
        return $this->getAllReels($userId, $seed);
    }

    public function getLikedReels($userId)
    {
        return RealUserLike::with([
            'real' => function ($query) use ($userId) {
                $query->likeExists($userId)->withUser();
            },
        ])
            ->where('user_id', $userId)
            ->orderByDesc('id')
            ->simplePaginate(self::PER_PAGE);
    }

    /**
     * NOTE(gap): "followed users' reels" needs the Follow social graph (not in the
     * Base yet). Falls back to the full feed. TODO(gap): filter by Follow.
     */
    public function getFollowedReels($userId, ?int $seed = null)
    {
        return $this->getAllReels($userId, $seed);
    }
}
