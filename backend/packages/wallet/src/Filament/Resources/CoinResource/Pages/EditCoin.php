<?php

namespace Utd\Wallet\Filament\Resources\CoinResource\Pages;

use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Utd\Wallet\Filament\Resources\CoinResource;

class EditCoin extends EditRecord
{
    protected static string $resource = CoinResource::class;

    protected function getHeaderActions(): array
    {
        return [DeleteAction::make()];
    }
}
