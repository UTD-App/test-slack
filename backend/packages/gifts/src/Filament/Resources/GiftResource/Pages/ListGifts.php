<?php

namespace Utd\Gifts\Filament\Resources\GiftResource\Pages;

use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Utd\Gifts\Filament\Resources\GiftResource;

class ListGifts extends ListRecords
{
    protected static string $resource = GiftResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()];
    }
}
