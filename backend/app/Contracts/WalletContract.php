<?php

namespace App\Contracts;

use App\Models\User;
use App\Support\Wallet\WalletResult;

/**
 * Economy primitive. Coins / Diamonds / Gifts / Payments / Games all move
 * balance through this contract — they never touch a wallet package directly.
 *
 * The Base ships a NullWallet (no provider installed). A Wallet package binds
 * its real implementation to this contract in its ServiceProvider::register().
 */
interface WalletContract
{
    /** Whether a real wallet provider is installed (vs the Null default). */
    public function isAvailable(): bool;

    /** Current balance of a currency for a user (0 when unavailable). */
    public function getBalance(User $user, string $currency = 'coins'): float;

    /** True if the user has at least $amount of $currency. */
    public function canAfford(User $user, string $currency, float $amount): bool;

    /** Add funds. Emits WalletCredited on success. */
    public function credit(User $user, string $currency, float $amount, string $reason, array $meta = []): WalletResult;

    /** Remove funds. Throws InsufficientFundsException if balance too low; emits WalletDebited on success. */
    public function debit(User $user, string $currency, float $amount, string $reason, array $meta = []): WalletResult;
}
