<?php

namespace Utd\Wallet\Filament\Resources\ChargeResource\Pages;

use App\Exceptions\InsufficientFundsException;
use App\Models\User;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;
use Utd\Wallet\Filament\Resources\ChargeResource;
use Utd\Wallet\Services\ChargeService;

class CreateCharge extends CreateRecord
{
    protected static string $resource = ChargeResource::class;

    protected function handleRecordCreation(array $data): Model
    {
        $target = User::findOrFail($data['user_id']);

        try {
            return app(ChargeService::class)->charge(
                target: $target,
                amount: (float) $data['amount'],
                direction: $data['direction'],
                charger: filament()->auth()->user(),
                reason: $data['reason'] ?? null,
                currency: $data['currency'] ?? config('wallet.default_currency', 'coins'),
            );
        } catch (InsufficientFundsException) {
            Notification::make()->danger()->title(__('wallet::admin.insufficient_coins'))->send();
            $this->halt();
        }
    }
}
