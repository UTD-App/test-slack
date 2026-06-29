<?php

namespace Utd\Wallet\Filament\Resources\CoinResource\Pages;

use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Utd\Wallet\Filament\Resources\CoinResource;

class ListCoins extends ListRecords
{
    protected static string $resource = CoinResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()];
    }
}
