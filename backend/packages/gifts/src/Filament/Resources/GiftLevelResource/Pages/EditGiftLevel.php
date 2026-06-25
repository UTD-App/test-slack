<?php

namespace Utd\Gifts\Filament\Resources\GiftLevelResource\Pages;

use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Utd\Gifts\Filament\Resources\GiftLevelResource;

class EditGiftLevel extends EditRecord
{
    protected static string $resource = GiftLevelResource::class;

    protected function getHeaderActions(): array
    {
        return [DeleteAction::make()];
    }
}
