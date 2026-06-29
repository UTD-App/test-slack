<?php

namespace Utd\Wallet\Filament\Resources\PaymentCoinResource\Pages;

use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Utd\Wallet\Filament\Resources\PaymentCoinResource;

class ListPaymentCoins extends ListRecords
{
    protected static string $resource = PaymentCoinResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()];
    }
}
