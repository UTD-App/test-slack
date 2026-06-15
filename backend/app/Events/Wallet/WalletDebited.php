<?php

namespace App\Events\Wallet;

use App\Models\User;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Fired by a wallet provider after a successful debit.
 */
class WalletDebited
{
    use Dispatchable;

    public function __construct(
        public readonly User $user,
        public readonly string $currency,
        public readonly float $amount,
        public readonly float $balance,
        public readonly string $reason,
        public readonly array $meta = [],
    ) {
    }
}
