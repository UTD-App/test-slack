<?php

namespace Utd\Gifts\Filament\Resources\UserResource\RelationManagers;

use App\Filament\Resources\UserResource;
use App\Filament\Tables\Columns\UserColumn;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

/**
 * "Gifts received" tab on the base User profile. Lists this user's received
 * gift_logs (paginated, read-only) — wired cross-package via a `giftsReceived`
 * relation injected onto the base User + registration in UserProfileTabRegistry.
 * Lazy + paginated, so it never slows the profile page load.
 */
class GiftsReceivedRelationManager extends RelationManager
{
    protected static string $relationship = 'giftsReceived';

    // Render inline (not lazy) so the active tab's data shows on page load —
    // Filament's lazy default loads on scroll-into-view (x-intersect), which under
    // the tall profile header leaves the active tab blank until scrolled.
    protected static bool $isLazy = false;

    public static function getTitle(Model $ownerRecord, string $pageClass): string
    {
        return __('gifts::admin.received_tab');
    }

    public static function getBadge(Model $ownerRecord, string $pageClass): ?string
    {
        return (string) $ownerRecord->giftsReceived()->count();
    }

    public function isReadOnly(): bool
    {
        return true;
    }

    /**
     * Gifts + coins this user RECEIVED in the current calendar month. One bounded
     * aggregate query (range filter on created_at → uses the receiver_id/created_at
     * index, not whereMonth). Computed only when this lazy tab is opened.
     */
    protected function monthStats(): array
    {
        $row = $this->getOwnerRecord()
            ->giftsReceived()
            ->where('created_at', '>=', now()->startOfMonth())
            ->selectRaw('COALESCE(SUM(gift_num),0) as qty, COALESCE(SUM(total_price),0) as coins')
            ->first();

        return [
            'qty'   => (int) ($row->qty ?? 0),
            'coins' => (float) ($row->coins ?? 0),
        ];
    }

    public function table(Table $table): Table
    {
        $stats = $this->monthStats();

        return $table
            ->header(view('gifts::filament.gift-month-stats', [
                'giftsLabel' => __('gifts::admin.month_received_gifts'),
                'giftsValue' => number_format($stats['qty']),
                'coinsLabel' => __('gifts::admin.month_received_coins'),
                'coinsValue' => number_format($stats['coins']),
            ]))
            ->modifyQueryUsing(fn (Builder $query) => $query->with('sender.profile'))
            ->columns([
                TextColumn::make('gift_name')->label(__('gifts::admin.gift'))->searchable(),
                TextColumn::make('gift_num')->label(__('gifts::admin.quantity'))->numeric()->sortable(),
                TextColumn::make('total_price')->label(__('gifts::admin.coins'))->numeric()->sortable(),
                UserColumn::make('sender')
                    ->label(__('gifts::admin.sender'))
                    ->profileUrl(fn ($record) => $record->sender_id
                        ? UserResource::getUrl('view', ['record' => $record->sender_id])
                        : null),
                TextColumn::make('created_at')->label(__('gifts::admin.date'))->dateTime()->sortable(),
            ])
            ->defaultSort('created_at', 'desc');
    }
}
