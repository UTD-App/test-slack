<?php

namespace Utd\Moment\Filament\Pages;

use App\Filament\Concerns\GatedByPackage;
use App\Models\User;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentCommint;
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

    /** Moment id whose likers panel is open (null = closed). */
    public ?int $likesFor = null;

    /** Moment id whose comments panel is open (null = closed). */
    public ?int $commentsFor = null;

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
            ->withUser()
            ->with('images')
            ->withCount(['likes', 'comments'])
            ->latest()
            ->paginate($this->perPage);
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
    }

    public function openComments(int $id): void
    {
        $this->commentsFor = $id;
        $this->likesFor = null;
    }

    public function closePanels(): void
    {
        $this->likesFor = null;
        $this->commentsFor = null;
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

    /** Comments (with author) of the currently-open moment. */
    public function getComments()
    {
        if (! $this->commentsFor) {
            return collect();
        }

        return MomentCommint::where('moment_id', $this->commentsFor)
            ->with('user:id,name,uuid,avatar')
            ->latest('id')
            ->get();
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
}
