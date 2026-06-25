<?php

use Illuminate\Support\Facades\Route;
use Utd\Wallet\Http\Controllers\CoinController;
use Utd\Wallet\Http\Controllers\WalletController;

/*
| Wallet package API routes. The provider wraps these with prefix('api')->middleware('api').
*/
Route::middleware(['auth:sanctum', 'checkLatestToken', 'generalBan', 'userBan', 'update.last.seen', 'localization'])
    ->group(function () {
        // Wallet (coin balance + ledger)
        Route::get('wallet/balances', [WalletController::class, 'balances']);
        Route::get('wallet/transactions', [WalletController::class, 'transactions']);

        // Coin catalogue (recharge screen)
        Route::get('coins', [CoinController::class, 'coins']);
        Route::get('coins/payment-methods', [CoinController::class, 'paymentMethods']);
    });
