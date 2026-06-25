<?php

namespace Utd\Wallet\Filament\Resources\ChargeResource\Pages;

use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Utd\Wallet\Filament\Resources\ChargeResource;

class ListCharges extends ListRecords
{
    protected static string $resource = ChargeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()->label(__('wallet::admin.charge_user')),
        ];
    }
}
