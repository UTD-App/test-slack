<?php

namespace Utd\Wallet\Services;

use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Utd\Wallet\Models\Charge;

/**
 * The single entry point for every manual charge (admin → user today; agencies /
 * area managers later, through the same method). It moves balance via the Wallet
 * (which writes the wallet_transactions ledger) and records a charge-specific
 * history row linked to that ledger entry. Works for any currency (coins, dollar…).
 */
class ChargeService
{
    /**
     * @param  string  $direction  'charge' (add) | 'deduct' (remove)
     * @param  Model|null  $charger  who performed it (AdminUser); null = system
     */
    public function charge(
        User $target,
        float $amount,
        string $direction = 'charge',
        ?Model $charger = null,
        ?string $reason = null,
        string $currency = 'coins',
        ?float $usd = null,
    ): Charge {
        return DB::transaction(function () use ($target, $amount, $direction, $charger, $reason, $currency, $usd) {
            $before = Wallet::getBalance($target, $currency);

            $result = $direction === 'charge'
                ? Wallet::credit($target, $currency, $amount, 'admin_charge', ['reason' => $reason])
                : Wallet::debit($target, $currency, $amount, 'admin_deduct', ['reason' => $reason]);

            return Charge::create([
                'charger_type'          => $charger?->getMorphClass(),
                'charger_id'            => $charger?->getKey(),
                'target_type'           => $target->getMorphClass(),
                'target_id'             => $target->getKey(),
                'currency'              => $currency,
                'amount'                => $direction === 'charge' ? $amount : -$amount,
                'balance_before'        => $before,
                'balance_after'         => $result->balance,
                'usd'                   => $usd,
                'reason'                => $reason,
                'wallet_transaction_id' => $result->transactionId,
            ]);
        });
    }
}
