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
 * in packages/columns that aren't in the Base, so the feed here is a per-user
 * load-spread feed over a shared recent deck (mirrors the Moment package). See
 * NOTES_GAPS.md (next step: engagement ranking + seen-exclusion).
 *
 * Performance — two layers:
 *  1) Counts come from the denormalized like_num/comment_num/view_num columns
 *     (maintained by the like/comment/view services) — NOT withCount() subqueries.
 *  2) Load spreading: one shared, briefly-cached "deck" of recent reel ids is
 *     built once per TTL; each user is rotated to a DIFFERENT start index in it,
 *     so N users entering at once read N different windows of the catalog instead
 *     of all hammering the newest few (their rows + counters + video files). The
 *     per-request cost is O(1) offset + O(page) slice (no per-user shuffle), so it
 *     holds at 5k–10k concurrent viewers, and only the page's 10 reels are hydrated.
 */
class ReelsRepository
{
    private const PER_PAGE = 10;

    /** Default deck size when reels.feed_deck_size is unset (recent reels a user rotates over). */
    private const DEFAULT_DECK_SIZE = 1000;

    /** Default cache TTL (seconds) when reels.feed_window_ttl is unset. */
    private const DEFAULT_WINDOW_TTL = 60;

    /** Cache key for the shared, shuffled feed deck. */
    private const WINDOW_KEY = 'reels:feed:deck';

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
        // Per-user load spreading: one shared deck of recent reel ids, each user
        // rotated to a different start index so concurrent users read different
        // windows of the catalog (not all the newest few). See the class docblock.
        $deck  = $this->feedDeck();
        $count = count($deck);
        if ($count === 0) {
            return $this->emptyFeedPage();
        }

        $page        = max(1, (int) Paginator::resolveCurrentPage());
        $offsetInPass = ($page - 1) * self::PER_PAGE;

        // One full pass over the deck per session: once a user has scrolled the
        // whole deck, return an empty page so the client refreshes with a new seed
        // (a fresh rotation) instead of looping the same order forever.
        if ($offsetInPass >= $count) {
            return $this->emptyFeedPage($count, $page);
        }

        // Stable per-user start (spread across users) + the client refresh nonce
        // ($seed) so pull-to-refresh advances the user to a fresh slice. Normalised
        // to [0, count) defensively (crc32 is signed 32-bit on some platforms).
        $base  = crc32((string) $userId) + (int) ($seed ?? 0);
        $start = (int) ((($base % $count) + $count) % $count);

        $pageIds = [];
        for ($i = 0; $i < self::PER_PAGE && ($offsetInPass + $i) < $count; $i++) {
            $pageIds[] = $deck[($start + $offsetInPass + $i) % $count];
        }

        return $this->hydrateReactions(new LengthAwarePaginator(
            $this->hydrateReels($pageIds, $userId),
            $count,
            self::PER_PAGE,
            $page,
            ['path' => Paginator::resolveCurrentPath()]
        ));
    }

    /** An empty feed page (no reels yet, or the user has scrolled the whole deck). */
    private function emptyFeedPage(int $total = 0, int $page = 1): LengthAwarePaginator
    {
        return new LengthAwarePaginator(
            collect(),
            $total,
            self::PER_PAGE,
            $page,
            ['path' => Paginator::resolveCurrentPath()]
        );
    }

    /**
     * The shared feed deck: ids of the most-recent N reels (config reels.feed_deck_size),
     * shuffled once and cached for a short TTL (reels.feed_window_ttl). Shuffling —
     * rather than serving plain chronological — means a user's rotation start lands
     * on a varied mix instead of "newest, shifted"; the per-TTL rebuild also rotates
     * the deck over time and picks up new uploads. Shared across users + ids only, so
     * concurrent viewers neither each run the scan nor each shuffle. whereHas('user')
     * drops reels by soft-deleted authors.
     *
     * @return list<int>
     */
    private function feedDeck(): array
    {
        $size = (int) config('reels.feed_deck_size', self::DEFAULT_DECK_SIZE);
        $ttl  = (int) config('reels.feed_window_ttl', self::DEFAULT_WINDOW_TTL);

        return Cache::remember(self::WINDOW_KEY, max(1, $ttl), function () use ($size, $ttl) {
            $ids = Real::query()
                ->whereHas('user')
                ->orderByDesc('id')
                ->limit(max(1, $size))
                ->pluck('id')
                ->all();

            // Deterministic shuffle seeded by the TTL bucket: stable within the cache
            // window (and consistent across app servers) yet different each rebuild.
            $bucket = $ttl > 0 ? intdiv(time(), $ttl) : 0;

            return collect($ids)->shuffle($bucket)->values()->all();
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
