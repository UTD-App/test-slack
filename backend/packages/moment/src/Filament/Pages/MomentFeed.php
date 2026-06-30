<?php

namespace Utd\Moment\Filament\Pages;

use App\Filament\Concerns\GatedByPackage;
use App\Models\User;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentComment;
use Utd\Moment\Entities\MomentLikes;

/**
 * Facebook-style moments feed for the admin panel:
 *  - left sidebar lists authors and filters the feed,
 *  - the feed loads more automatically as you reach the bottom (infinite scroll),
 *  - clicking the like / comment counters opens a panel listing the people involved,
 *  - clicking an image opens a lightbox (handled client-side with Alpine).
 */
class MomentFeed extends Page
{
    use GatedByPackage;

    protected static ?string $packageSlug = 'moment';

    protected static ?string $navigationIcon = 'heroicon-o-photo';

    protected static ?int $navigationSort = 1;

    protected static string $view = 'moment::filament.pages.moment-feed';

    public static function getNavigationGroup(): ?string
    {
        return __('moment::admin.nav_group');
    }

    public static function getNavigationLabel(): string
    {
        return __('moment::admin.moments');
    }

    public function getTitle(): string
    {
        return __('moment::admin.moments');
    }

    /** Author (user id) the feed is filtered by (null = all). */
    public ?int $authorFilter = null;

    // ---- Feed filters (bound to the toolbar) -------------------------------
    /** Free-text search across author name / uuid. */
    public string $search = '';

    /** Created-at range (Y-m-d, inclusive). */
    public ?string $dateFrom = null;

    public ?string $dateTo = null;

    /** Content type: all | media | text | video. */
    public string $contentType = 'all';

    /** Minimum engagement thresholds (0 / blank = off). */
    public ?int $minLikes = null;

    public ?int $minComments = null;

    public ?int $minGifts = null;

    /** Only moments that received at least one gift. */
    public bool $hasGifts = false;

    /** Only moments that have at least one report. */
    public bool $reportedOnly = false;

    /** Gifts panel ordering: newest | top (highest total value). */
    public string $giftSort = 'newest';

    /** Filter property names that should reset the feed window when changed. */
    private const FILTER_PROPS = [
        'search', 'dateFrom', 'dateTo', 'contentType',
        'minLikes', 'minComments', 'minGifts', 'hasGifts',
        'reportedOnly', 'authorFilter',
    ];

    /** Moment id whose likers panel is open (null = closed). */
    public ?int $likesFor = null;

    /** Moment id whose comments panel is open (null = closed). */
    public ?int $commentsFor = null;

    /** Moment id whose gifts panel is open (null = closed). */
    public ?int $giftsFor = null;

    /** Per-request memo for whether the Gifts package (gift_logs table) is installed. */
    private ?bool $giftsAvailableMemo = null;

    /** How many moments are currently loaded (grows as the user scrolls). */
    public int $perPage = 8;

    /** Number of moments pulled in per "load more" step. */
    private const STEP = 8;

    public static function canAccess(): bool
    {
        // Hidden the instant the Moment package is disabled in admin/packages.
        if (! static::packageIsEnabled()) {
            return false;
        }

        return filament()->auth()->user()?->hasAnyRole(['super_admin', 'user_manager']) ?? false;
    }

    public function getMoments()
    {
        return Moment::query()
            ->whereHas('user')
            ->when($this->authorFilter, fn ($q) => $q->where('user_id', $this->authorFilter))
            ->when(filled($this->search), function ($q) {
                $term = trim($this->search);
                $q->whereHas('user', fn ($u) => $u
                    ->where('name', 'like', "%{$term}%")
                    ->orWhere('uuid', 'like', "%{$term}%"));
            })
            ->when(filled($this->dateFrom), fn ($q) => $q->whereDate('created_at', '>=', $this->dateFrom))
            ->when(filled($this->dateTo), fn ($q) => $q->whereDate('created_at', '<=', $this->dateTo))
            ->when($this->contentType !== 'all', fn ($q) => $this->applyContentType($q))
            ->when((int) $this->minLikes > 0, fn ($q) => $q->has('likes', '>=', (int) $this->minLikes))
            ->when((int) $this->minComments > 0, fn ($q) => $q->has('comments', '>=', (int) $this->minComments))
            ->when($this->reportedOnly, fn ($q) => $q->has('reports'))
            ->when($this->hasGifts && $this->giftsAvailable(), fn ($q) => $q->whereIn('id', $this->giftedMomentIds()))
            ->when((int) $this->minGifts > 0 && $this->giftsAvailable(), fn ($q) => $q->whereIn('id', $this->giftedMomentIds((int) $this->minGifts)))
            ->withUser()
            ->with('images')
            ->withCount(['likes', 'comments', 'reports', 'commentReports'])
            ->latest()
            ->paginate($this->perPage);
    }

    /** Constrain the query by content type (media / text-only / video). */
    private function applyContentType($q): void
    {
        $videoLike = fn ($col, $b) => $b
            ->where($col, 'like', '%.mp4')
            ->orWhere($col, 'like', '%.mov')
            ->orWhere($col, 'like', '%.webm');

        match ($this->contentType) {
            'media' => $q->where(fn ($w) => $w
                ->whereHas('images')
                ->orWhere(fn ($i) => $i->whereNotNull('img')->where('img', '!=', ''))),
            'text' => $q->whereDoesntHave('images')
                ->where(fn ($w) => $w->whereNull('img')->orWhere('img', '')),
            'video' => $q->where(fn ($w) => $w
                ->whereHas('images', fn ($i) => $i->where(fn ($b) => $videoLike('image', $b)))
                ->orWhere(fn ($b) => $videoLike('img', $b))),
            default => null,
        };
    }

    /** Moment ids that received gifts (optionally at least $min of them). */
    private function giftedMomentIds(int $min = 1): array
    {
        return DB::table('gift_logs')
            ->where('context_type', 'moment')
            ->groupBy('context_id')
            ->havingRaw('count(*) >= ?', [$min])
            ->pluck('context_id')
            ->all();
    }

    /** How many feed filters are currently active (for the toolbar badge). */
    public function getActiveFilterCount(): int
    {
        return collect([
            filled($this->search),
            filled($this->dateFrom),
            filled($this->dateTo),
            $this->contentType !== 'all',
            (int) $this->minLikes > 0,
            (int) $this->minComments > 0,
            (int) $this->minGifts > 0,
            $this->hasGifts,
            $this->reportedOnly,
        ])->filter()->count();
    }

    /** Reset the feed window whenever a filter changes (live-updating toolbar). */
    public function updated($property): void
    {
        if (in_array($property, self::FILTER_PROPS, true)) {
            $this->perPage = self::STEP;
        }
    }

    /** Clear every feed filter. */
    public function resetFilters(): void
    {
        $this->reset(self::FILTER_PROPS);
        $this->contentType = 'all';
        $this->perPage = self::STEP;
    }

    /** Pull in the next batch of moments (called automatically on scroll). */
    public function loadMore(): void
    {
        $this->perPage += self::STEP;
    }

    /** Authors that have moments, with their moment counts (for the sidebar filter). */
    public function getAuthors()
    {
        $counts = Moment::query()
            ->selectRaw('user_id, count(*) as total')
            ->groupBy('user_id')
            ->pluck('total', 'user_id');

        if ($counts->isEmpty()) {
            return collect();
        }

        return User::query()
            ->whereIn('id', $counts->keys())
            ->orderBy('name')
            ->get(['id', 'name', 'uuid', 'avatar'])
            ->each(fn (User $u) => $u->moments_total = (int) ($counts[$u->id] ?? 0));
    }

    public function filterByAuthor(?int $id): void
    {
        $this->authorFilter = $id;
        $this->perPage = self::STEP;
    }

    public function openLikes(int $id): void
    {
        $this->likesFor = $id;
        $this->commentsFor = null;
        $this->giftsFor = null;
    }

    public function openComments(int $id): void
    {
        $this->commentsFor = $id;
        $this->likesFor = null;
        $this->giftsFor = null;
    }

    public function openGifts(int $id): void
    {
        $this->giftsFor = $id;
        $this->giftSort = 'newest';
        $this->likesFor = null;
        $this->commentsFor = null;
    }

    /** Switch the gifts panel ordering (newest | top by value). */
    public function sortGifts(string $sort): void
    {
        $this->giftSort = in_array($sort, ['newest', 'top'], true) ? $sort : 'newest';
    }

    public function closePanels(): void
    {
        $this->likesFor = null;
        $this->commentsFor = null;
        $this->giftsFor = null;
    }

    /** The moment id of whichever engagement panel is currently open (null = none). */
    public function getPanelMomentId(): ?int
    {
        return $this->likesFor ?? $this->commentsFor ?? $this->giftsFor;
    }

    /** Likes / comments / gifts counts for the open moment (for the panel tabs). */
    public function panelCounts(): array
    {
        $id = $this->getPanelMomentId();

        if (! $id) {
            return ['likes' => 0, 'comments' => 0, 'gifts' => 0];
        }

        return [
            'likes' => MomentLikes::where('moment_id', $id)->count(),
            'comments' => MomentComment::where('moment_id', $id)->count(),
            'gifts' => $this->giftsAvailable()
                ? (int) DB::table('gift_logs')->where('context_type', 'moment')->where('context_id', $id)->count()
                : 0,
        ];
    }

    /** Users who liked the currently-open moment. */
    public function getLikers()
    {
        if (! $this->likesFor) {
            return collect();
        }

        return MomentLikes::where('moment_id', $this->likesFor)
            ->with('user:id,name,uuid,avatar')
            ->latest('id')
            ->get();
    }

    /**
     * Comments of the open moment, flattened into thread order: each comment is
     * immediately followed by its replies (depth-first). Every item carries a
     * ->depth (0 = top-level) and ->parentComment (the comment it replies to, or
     * null) so the view can indent replies and show a "replying to …" label.
     * Replies whose parent was deleted resurface as top-level (orphan = root).
     */
    public function getComments()
    {
        if (! $this->commentsFor) {
            return collect();
        }

        $all = MomentComment::where('moment_id', $this->commentsFor)
            ->with('user:id,name,uuid,avatar,status')
            ->orderBy('id')
            ->get();

        $byId = $all->keyBy('id');

        // Group by effective parent (0 = root; orphans whose parent is gone => root).
        $children = $all->groupBy(function ($c) use ($byId) {
            $pid = (int) ($c->parent_id ?? 0);

            return ($pid && $byId->has($pid)) ? $pid : 0;
        });

        $ordered = collect();
        $walk = function ($parentId, $depth) use (&$walk, $children, $byId, $ordered) {
            foreach ($children->get($parentId, collect()) as $c) {
                $c->depth = $depth;
                $c->parentComment = $depth > 0 ? $byId->get((int) $c->parent_id) : null;
                $ordered->push($c);
                $walk((int) $c->id, min($depth + 1, 4)); // cap visual nesting at 4
            }
        };
        $walk(0, 0);

        return $ordered;
    }

    /** Whether the optional Gifts package is installed (gift_logs table present). */
    public function giftsAvailable(): bool
    {
        return $this->giftsAvailableMemo ??= Schema::hasTable('gift_logs');
    }

    /**
     * Gifts sent on the currently-open moment, newest first. Read straight from
     * the gifts package's denormalized gift_logs table (gift_name/unit_price/…)
     * with a raw query so this package never hard-depends on the Gifts package.
     * Each row gets its sender User attached and created_at parsed to Carbon.
     */
    public function getGifts()
    {
        if (! $this->giftsFor || ! $this->giftsAvailable()) {
            return collect();
        }

        $rows = DB::table('gift_logs')
            ->where('context_type', 'moment')
            ->where('context_id', $this->giftsFor)
            ->when($this->giftSort === 'top', fn ($q) => $q->orderByDesc('total_price'))
            ->when($this->giftSort !== 'top', fn ($q) => $q->orderByDesc('created_at'))
            ->get();

        if ($rows->isEmpty()) {
            return collect();
        }

        $senders = User::whereIn('id', $rows->pluck('sender_id')->filter()->unique())
            ->get(['id', 'name', 'uuid', 'avatar'])
            ->keyBy('id');

        return $rows->map(function ($row) use ($senders) {
            $row->sender = $senders->get($row->sender_id);
            $row->created_at = $row->created_at ? Carbon::parse($row->created_at) : null;

            return $row;
        });
    }

    /** Gift counts for the loaded moments (one grouped query) → [moment_id => count]. */
    public function giftCountsFor($momentIds): array
    {
        if (! $this->giftsAvailable() || empty($momentIds)) {
            return [];
        }

        return DB::table('gift_logs')
            ->where('context_type', 'moment')
            ->whereIn('context_id', $momentIds)
            ->groupBy('context_id')
            ->selectRaw('context_id, count(*) as c')
            ->pluck('c', 'context_id')
            ->all();
    }

    public function deleteMoment(int $id): void
    {
        Moment::whereKey($id)->delete();
        $this->closePanels();

        Notification::make()
            ->title(__('moment::admin.moment_deleted'))
            ->success()
            ->send();
    }

    /** Delete a single comment and keep the moment's cached comment_num in sync. */
    public function deleteComment(int $commentId): void
    {
        $comment = MomentComment::find($commentId);

        if (! $comment) {
            return;
        }

        $momentId = $comment->moment_id;
        $comment->delete();

        // Keep the denormalized counter the mobile API reads; never go negative.
        Moment::whereKey($momentId)->where('comment_num', '>', 0)->decrement('comment_num');

        Notification::make()
            ->title(__('moment::admin.comment_deleted'))
            ->success()
            ->send();
    }

    /** Ban the author of a comment — same semantics as the user ban (status=0). */
    public function banCommenter(int $userId): void
    {
        $user = User::find($userId);

        if (! $user) {
            return;
        }

        $user->update(['status' => 0]);

        Notification::make()
            ->title(__('moment::admin.commenter_banned'))
            ->success()
            ->send();
    }
}
