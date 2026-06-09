<?php

namespace App\Facades;

use App\Contracts\WalletContract;
use App\Models\User;
use App\Support\Wallet\WalletResult;
use Illuminate\Support\Facades\Facade;

/**
 * @method static bool isAvailable()
 * @method static float getBalance(User $user, string $currency = 'coins')
 * @method static bool canAfford(User $user, string $currency, float $amount)
 * @method static WalletResult credit(User $user, string $currency, float $amount, string $reason, array $meta = [])
 * @method static WalletResult debit(User $user, string $currency, float $amount, string $reason, array $meta = [])
 *
 * @see \App\Contracts\WalletContract
 */
class Wallet extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return WalletContract::class;
    }
}
