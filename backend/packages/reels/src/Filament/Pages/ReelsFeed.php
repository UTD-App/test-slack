<?php

namespace Utd\Reels\Filament\Pages;

use App\Filament\Concerns\GatedByPackage;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Collection;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealUserComment;
use Utd\Reels\Entities\RealUserLike;

/**
 * Facebook-style reel viewer for the admin panel: one immersive reel at a time,
 * navigate with the up/down arrows. Navigation is server-driven (Livewire) so the
 * markup stays simple/robust; only play/pause + mute are client-side (Alpine).
 */
class ReelsFeed extends Page
{
    use GatedByPackage;

    protected static ?string $packageSlug = 'reels';

    protected static ?string $navigationIcon = 'heroicon-o-film';

    protected static ?int $navigationSort = 1;

    protected static string $view = 'reels::filament.pages.reels-feed';

    /** How many of the latest reels are browsable. */
    private const LIMIT = 50;

    /** Index of the reel currently shown. */
    public int $index = 0;

    /** Per-page-load shuffle seed: re-randomised on every fresh load (mount), but
     *  kept stable across Livewire requests so scrolling doesn't reshuffle. */
    public ?int $seed = null;

    /** Username filter (matches reels whose author name contains this text). */
    public ?string $search = '';

    /** Reel id whose likers panel is open (null = closed). */
    public ?int $likesFor = null;

    /** Reel id whose comments panel is open (null = closed). */
    public ?int $commentsFor = null;

    private ?Collection $reelsCache = null;

    public static function getNavigationGroup(): ?string
    {
        return __('reels::admin.nav_group');
    }

    public static function getNavigationLabel(): string
    {
        return __('reels::admin.reels');
    }

    public function getTitle(): string
    {
        return __('reels::admin.reels');
    }

    public function mount(): void
    {
        // New random order on every fresh page load (refresh).
        $this->seed = random_int(1, 1_000_000_000);
    }

    public static function canAccess(): bool
    {
        if (! static::packageIsEnabled()) {
            return false;
        }

        return filament()->auth()->user()?->hasAnyRole(['super_admin', 'user_manager']) ?? false;
    }

    /** Reset to the first match whenever the username filter changes. */
    public function updatedSearch(): void
    {
        $this->index = 0;
        $this->reelsCache = null;
        $this->closePanels();
    }

    /** Latest reels (newest first), memoized for the request. */
    public function reels(): Collection
    {
        return $this->reelsCache ??= Real::query()
            // Always require an author; when filtering, match the author's name.
            ->whereHas('user', function ($u) {
                if (filled($this->search)) {
                    $u->where('name', 'like', '%' . trim($this->search) . '%');
                }
            })
            ->withUser()
            // Counts read from the denormalized like_num/comment_num/view_num
            // columns (no per-row withCount subqueries).
            ->latest('id')
            ->limit(self::LIMIT)
            ->get()
            // Shuffle with the per-load seed: a fresh order on each refresh, but the
            // SAME order for every Livewire request in this session (so scrolling is
            // consistent). DB-agnostic (works on MySQL and the sqlite test DB).
            ->shuffle($this->seed)
            ->values();
    }

    public function getTotalProperty(): int
    {
        return $this->reels()->count();
    }

    /** The reel currently on screen (null when there are none). */
    public function getCurrentProperty(): ?Real
    {
        $reels = $this->reels();
        if ($reels->isEmpty()) {
            return null;
        }

        $this->index = max(0, min($this->index, $reels->count() - 1));

        return $reels[$this->index];
    }

    public function next(): void
    {
        if ($this->index < $this->reels()->count() - 1) {
            $this->index++;
            $this->closePanels();
        }
    }

    public function prev(): void
    {
        if ($this->index > 0) {
            $this->index--;
            $this->closePanels();
        }
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

    public function getLikers()
    {
        if (! $this->likesFor) {
            return collect();
        }

        return RealUserLike::where('real_id', $this->likesFor)
            ->with('user:id,name,uuid,avatar')
            ->latest('id')
            ->get();
    }

    public function getComments()
    {
        if (! $this->commentsFor) {
            return collect();
        }

        return RealUserComment::where('real_id', $this->commentsFor)
            ->with('user:id,name,uuid,avatar')
            ->latest('id')
            ->get();
    }

    public function deleteReel(int $id): void
    {
        Real::whereKey($id)->delete();
        $this->reelsCache = null;
        $this->closePanels();

        if ($this->index >= $this->reels()->count()) {
            $this->index = max(0, $this->reels()->count() - 1);
        }

        Notification::make()
            ->title(__('reels::admin.reel_deleted'))
            ->success()
            ->send();
    }
}
