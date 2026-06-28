<?php

namespace Utd\Reels\Filament\Resources\UserResource\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\Layout\View as ViewLayout;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;

/**
 * "Reels" tab on the base User profile — this user's reels (paginated, read-only).
 * Wired via a `userReels` relation injected onto the base User + registration in
 * UserProfileTabRegistry. Lazy + paginated → no cost on profile page load.
 *
 * Rendered as a card GRID (contentGrid) where each reel shows a SMALL inline
 * video player (`preload="metadata"` so only the first frame is fetched, never
 * the whole file) plus its description and engagement counters.
 */
class UserReelsRelationManager extends RelationManager
{
    protected static string $relationship = 'userReels';

    // Render inline (not lazy) so the active tab's data shows on page load —
    // Filament's lazy default loads on scroll-into-view (x-intersect), which under
    // the tall profile header leaves the active tab blank until scrolled.
    protected static bool $isLazy = false;

    public static function getTitle(Model $ownerRecord, string $pageClass): string
    {
        return __('reels::admin.reels');
    }

    public static function getBadge(Model $ownerRecord, string $pageClass): ?string
    {
        return (string) $ownerRecord->userReels()->count();
    }

    public function isReadOnly(): bool
    {
        return true;
    }

    public function table(Table $table): Table
    {
        return $table
            ->contentGrid(['md' => 2, 'xl' => 3])
            ->columns([
                ViewLayout::make('reels::filament.reel-card'),
            ])
            ->defaultSort('created_at', 'desc')
            ->paginationPageOptions([12, 24, 48]);
    }

    /**
     * Normalise a stored media value to a host-relative URL for the admin web:
     * our own `…/storage/x` → `/storage/x`, bare paths → `/storage/x`, external
     * absolute URLs pass through unchanged. Mirrors the dashboard media convention.
     */
    public static function mediaUrl(?string $path): ?string
    {
        if ($path === null || $path === '') {
            return null;
        }
        if (preg_match('#^https?://#i', $path)) {
            if (preg_match('#/storage/(.+)$#', $path, $m)) {
                return '/storage/' . $m[1];
            }
            return $path;
        }
        return '/storage/' . ltrim($path, '/');
    }
}
