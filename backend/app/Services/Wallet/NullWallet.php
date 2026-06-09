<?php

namespace App\Services\Wallet;

use App\Contracts\WalletContract;
use App\Exceptions\WalletProviderMissingException;
use App\Models\User;
use App\Support\Wallet\WalletResult;

/**
 * Default wallet used when no Wallet package is installed.
 * Reads are safe (balance 0); writes throw so money operations never silently no-op.
 */
class NullWallet implements WalletContract
{
    public function isAvailable(): bool
    {
        return false;
    }

    public function getBalance(User $user, string $currency = 'coins'): float
    {
        return 0.0;
    }

    public function canAfford(User $user, string $currency, float $amount): bool
    {
        return false;
    }

    public function credit(User $user, string $currency, float $amount, string $reason, array $meta = []): WalletResult
    {
        throw new WalletProviderMissingException();
    }

    public function debit(User $user, string $currency, float $amount, string $reason, array $meta = []): WalletResult
    {
        throw new WalletProviderMissingException();
    }
}
