<?php

namespace Utd\Gifts\Filament\Resources\GiftCategoryResource\Pages;

use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Utd\Gifts\Filament\Resources\GiftCategoryResource;

class ListGiftCategories extends ListRecords
{
    protected static string $resource = GiftCategoryResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()];
    }
}
