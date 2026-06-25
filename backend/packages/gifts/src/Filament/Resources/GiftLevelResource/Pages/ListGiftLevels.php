<?php

namespace Utd\Gifts\Filament\Resources\GiftLevelResource\Pages;

use Filament\Actions\CreateAction;
use Filament\Resources\Components\Tab;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Database\Eloquent\Builder;
use Utd\Gifts\Filament\Resources\GiftLevelResource;
use Utd\Gifts\Models\GiftLevel;

class ListGiftLevels extends ListRecords
{
    protected static string $resource = GiftLevelResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()];
    }

    /** Sender / Receiver tabs over the single level table. */
    public function getTabs(): array
    {
        return [
            'all' => Tab::make(__('gifts::admin.tab_all')),
            'sender' => Tab::make(__('gifts::admin.kind_sender'))
                ->modifyQueryUsing(fn (Builder $query) => $query->where('kind', GiftLevel::KIND_SENDER)),
            'receiver' => Tab::make(__('gifts::admin.kind_receiver'))
                ->modifyQueryUsing(fn (Builder $query) => $query->where('kind', GiftLevel::KIND_RECEIVER)),
        ];
    }
}
