<?php

namespace Utd\Gifts\Filament\Resources\GiftCategoryResource\Pages;

use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Utd\Gifts\Filament\Resources\GiftCategoryResource;

class EditGiftCategory extends EditRecord
{
    protected static string $resource = GiftCategoryResource::class;

    protected function getHeaderActions(): array
    {
        return [DeleteAction::make()];
    }
}
