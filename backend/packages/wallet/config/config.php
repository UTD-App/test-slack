<?php

return [

    // When false, the package binds NullWallet (reads 0, writes throw).
    'enabled' => env('WALLET_ENABLED', true),

    'default_currency' => 'coins',

    /*
    | Supported currencies. This package owns COINS only (in-app spendable).
    | The dollar/earnings wallet + withdrawals live in the `target` package, and
    | diamonds in the `agency`/`gifts` packages — a dollar->coins conversion is
    | recorded here as a wallet_transactions row of type `exchange`.
    | Extensible: add a string here and DatabaseWallet serves it with no schema change.
    */
    'currencies' => ['coins'],

];
