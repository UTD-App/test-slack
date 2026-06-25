<?php

namespace Utd\Wallet\Http\Controllers;

use App\Facades\Wallet;
use App\Helpers\Common;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Utd\Wallet\Models\UserWallet;
use Utd\Wallet\Models\WalletTransaction;

class WalletController extends Controller
{
    /** All wallet balances for the authenticated user (coins, dollar, …). */
    public function balances(Request $request)
    {
        $user    = $request->user();
        $wallets = UserWallet::where('user_id', $user->getKey())->get()->keyBy('currency');

        $balances = collect(config('wallet.currencies', ['coins']))->map(function (string $currency) use ($user, $wallets) {
            $wallet = $wallets->get($currency);

            return [
                'currency'  => $currency,
                'balance'   => $wallet ? (float) $wallet->balance : Wallet::getBalance($user, $currency),
                'available' => $wallet ? (float) $wallet->available : 0.0,
            ];
        })->values();

        return Common::apiResponse(true, 'balances', $balances);
    }

    /**
     * Paginated ledger for one currency (newest first).
     *
     * Query: currency, type, start_date (Y-m-d), end_date (Y-m-d), per_page, page.
     * Each row is mapped to a flat, client-friendly payload so the app does not
     * depend on raw column names.
     */
    public function transactions(Request $request)
    {
        $currency = $request->string('currency')->toString() ?: config('wallet.default_currency', 'coins');

        // Clamp page size: never let a client pull an unbounded number of rows (DoS).
        $perPage = max(1, min((int) $request->integer('per_page', 20), 100));

        $transactions = WalletTransaction::where('user_id', $request->user()->getKey())
            ->where('currency', $currency)
            ->when($request->filled('type'), fn ($q) => $q->where('type', $request->string('type')->toString()))
            ->when($request->filled('start_date'), fn ($q) => $q->whereDate('created_at', '>=', $request->string('start_date')->toString()))
            ->when($request->filled('end_date'), fn ($q) => $q->whereDate('created_at', '<=', $request->string('end_date')->toString()))
            ->latest()
            ->paginate($perPage)
            ->through(fn (WalletTransaction $tx) => $this->presentTransaction($tx));

        return Common::apiResponse(true, 'transactions', $transactions);
    }

    /** Flatten a ledger row into the API shape the app consumes. */
    private function presentTransaction(WalletTransaction $tx): array
    {
        $amount = (float) $tx->amount;

        return [
            'id'             => $tx->id,
            'currency'       => $tx->currency,
            'type'           => $tx->type,
            'direction'      => $amount < 0 ? 'debit' : 'credit',
            'amount'         => $amount,
            'abs_amount'     => abs($amount),
            'balance_after'  => (float) $tx->balance_after,
            'reason'         => $tx->meta['reason'] ?? $tx->type,
            'reference_type' => $tx->reference_type ? class_basename($tx->reference_type) : null,
            'created_at'     => optional($tx->created_at)->toIso8601String(),
        ];
    }
}
