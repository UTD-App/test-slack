<?php

namespace Utd\Wallet\Filament\Resources\PaymentCoinResource\Pages;

use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Utd\Wallet\Filament\Resources\PaymentCoinResource;

class EditPaymentCoin extends EditRecord
{
    protected static string $resource = PaymentCoinResource::class;

    protected function getHeaderActions(): array
    {
        return [DeleteAction::make()];
    }
}
