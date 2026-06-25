<?php

namespace Utd\Moment\Filament\Resources\UserResource\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\Layout\View as ViewLayout;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

/**
 * "Moments" tab on the base User profile — this user's moments (paginated,
 * read-only). Wired via a `userMoments` relation injected onto the base User +
 * registration in UserProfileTabRegistry. Lazy + paginated.
 *
 * Rendered as a card GRID (contentGrid) where each moment shows its media in a
 * SMALL thumbnail (single `img` or the first gallery image) plus the caption and
 * engagement counts. Gallery images are eager-loaded to avoid an N+1 per page.
 */
class UserMomentsRelationManager extends RelationManager
{
    protected static string $relationship = 'userMoments';

    // Render inline (not lazy) so the active tab's data shows on page load —
    // Filament's lazy default loads on scroll-into-view (x-intersect), which under
    // the tall profile header leaves the active tab blank until scrolled.
    protected static bool $isLazy = false;

    public static function getTitle(Model $ownerRecord, string $pageClass): string
    {
        return __('moment::admin.moments');
    }

    public static function getBadge(Model $ownerRecord, string $pageClass): ?string
    {
        return (string) $ownerRecord->userMoments()->count();
    }

    public function isReadOnly(): bool
    {
        return true;
    }

    public function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with('images'))
            ->contentGrid(['md' => 2, 'xl' => 3])
            ->columns([
                ViewLayout::make('moment::filament.moment-card'),
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
