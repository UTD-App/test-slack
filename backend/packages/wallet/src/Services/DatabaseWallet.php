<?php

namespace Utd\Wallet\Services;

use App\Contracts\WalletContract;
use App\Events\Wallet\WalletCredited;
use App\Events\Wallet\WalletDebited;
use App\Exceptions\InsufficientFundsException;
use App\Models\User;
use App\Support\Wallet\WalletResult;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use Utd\Wallet\Models\UserWallet;
use Utd\Wallet\Models\WalletTransaction;

/**
 * Multi-currency, DB-backed wallet. Each (user, currency) is its own row in
 * user_wallets; every move is row-locked, appended to the wallet_transactions
 * ledger, and announced via WalletCredited / WalletDebited.
 *
 * Currency-agnostic: any string in config('wallet.currencies') is a valid wallet.
 * Ships coins + dollar; Agency adds diamonds with no code change.
 */
class DatabaseWallet implements WalletContract
{
    public function isAvailable(): bool
    {
        return true;
    }

    public function getBalance(User $user, string $currency = 'coins'): float
    {
        $this->assertCurrency($currency);

        return (float) (UserWallet::query()
            ->where('user_id', $user->getKey())
            ->where('currency', $currency)
            ->value('balance') ?? 0);
    }

    public function canAfford(User $user, string $currency, float $amount): bool
    {
        return $this->available($user, $currency) >= $amount;
    }

    public function credit(User $user, string $currency, float $amount, string $reason, array $meta = []): WalletResult
    {
        $this->assertPositive($amount);

        return $this->move($user, $currency, $amount, $reason, $meta, isCredit: true);
    }

    public function debit(User $user, string $currency, float $amount, string $reason, array $meta = []): WalletResult
    {
        $this->assertPositive($amount);

        return $this->move($user, $currency, $amount, $reason, $meta, isCredit: false);
    }

    /** Available = balance - held (held = reserved for pending withdrawals). */
    private function available(User $user, string $currency): float
    {
        $this->assertCurrency($currency);

        $wallet = UserWallet::query()
            ->where('user_id', $user->getKey())
            ->where('currency', $currency)
            ->first();

        return $wallet ? (float) $wallet->available : 0.0;
    }

    private function move(User $user, string $currency, float $amount, string $reason, array $meta, bool $isCredit): WalletResult
    {
        $this->assertCurrency($currency);

        // Idempotency: a caller that retries the same money op (payment webhook,
        // gift, exchange) passes meta['idempotency_key']; we replay the prior
        // ledger row instead of moving balance a second time.
        $key = $meta['idempotency_key'] ?? null;
        if ($key !== null && ($existing = WalletTransaction::where('idempotency_key', $key)->first())) {
            return $this->resultFromTransaction($existing);
        }

        try {
            return DB::transaction(function () use ($user, $currency, $amount, $reason, $meta, $isCredit, $key) {
                $wallet = $this->lockOrCreateWallet($user, $currency);

                // All money math is done with bcmath on the decimal(20,2) strings —
                // no float rounding drift on the stored balance.
                $before    = $this->money($wallet->balance);
                $held      = $this->money($wallet->held);
                $amountStr = $this->money($amount);
                $available = bcsub($before, $held, 2);

                if (! $isCredit && bccomp($available, $amountStr, 2) < 0) {
                    throw new InsufficientFundsException($currency, $amount, (float) $available);
                }

                $after = $isCredit ? bcadd($before, $amountStr, 2) : bcsub($before, $amountStr, 2);

                $wallet->balance = $after;
                $wallet->save();

                $tx = WalletTransaction::create([
                    'wallet_id'       => $wallet->getKey(),
                    'user_id'         => $user->getKey(),
                    'currency'        => $currency,
                    'type'            => $reason,
                    'amount'          => $isCredit ? $amountStr : '-' . $amountStr,
                    'balance_before'  => $before,
                    'balance_after'   => $after,
                    'reference_type'  => $meta['reference_type'] ?? null,
                    'reference_id'    => $meta['reference_id'] ?? null,
                    'idempotency_key' => $key,
                    'meta'            => $meta ?: null,
                ]);

                $event = $isCredit
                    ? new WalletCredited($user, $currency, $amount, (float) $after, $reason, $meta)
                    : new WalletDebited($user, $currency, $amount, (float) $after, $reason, $meta);
                event($event);

                return new WalletResult(
                    success: true,
                    currency: $currency,
                    amount: (float) $amountStr,
                    balance: (float) $after,
                    reason: $reason,
                    transactionId: (string) $tx->getKey(),
                    meta: $meta,
                );
            });
        } catch (QueryException $e) {
            // Lost the idempotency-key unique race to a concurrent identical call —
            // replay the row the winner wrote rather than erroring.
            if ($key !== null && ($existing = WalletTransaction::where('idempotency_key', $key)->first())) {
                return $this->resultFromTransaction($existing);
            }
            throw $e;
        }
    }

    /**
     * Fetch the (user, currency) wallet locked FOR UPDATE, creating it if absent.
     * The unique(user_id, currency) index makes the create race-safe: if a
     * concurrent first-move created it first, we swallow the duplicate and re-fetch
     * the now-committed row (locked) instead of bubbling a 500.
     */
    private function lockOrCreateWallet(User $user, string $currency): UserWallet
    {
        $find = fn () => UserWallet::query()
            ->where('user_id', $user->getKey())
            ->where('currency', $currency)
            ->lockForUpdate()
            ->first();

        if ($wallet = $find()) {
            return $wallet;
        }

        try {
            UserWallet::create(['user_id' => $user->getKey(), 'currency' => $currency]);
        } catch (QueryException $e) {
            if (! $find()) {
                throw $e;
            }
        }

        return $find();
    }

    /** Normalise any numeric/decimal value to a fixed 2-decimal string for bcmath. */
    private function money(int|float|string $value): string
    {
        return number_format((float) $value, 2, '.', '');
    }

    /** Rebuild a WalletResult from an already-persisted ledger row (idempotent replay). */
    private function resultFromTransaction(WalletTransaction $tx): WalletResult
    {
        return new WalletResult(
            success: true,
            currency: $tx->currency,
            amount: abs((float) $tx->amount),
            balance: (float) $tx->balance_after,
            reason: $tx->type,
            transactionId: (string) $tx->getKey(),
            meta: is_array($tx->meta) ? $tx->meta : [],
        );
    }

    private function assertCurrency(string $currency): void
    {
        if (! in_array($currency, config('wallet.currencies', ['coins']), true)) {
            throw new InvalidArgumentException("Unsupported wallet currency [{$currency}].");
        }
    }

    private function assertPositive(float $amount): void
    {
        if ($amount <= 0) {
            throw new InvalidArgumentException('Wallet amount must be greater than zero.');
        }
    }
}
