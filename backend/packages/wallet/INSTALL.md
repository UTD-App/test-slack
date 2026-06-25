# Utd\Wallet — install (manual drop-in)

Standalone composer package (namespace `Utd\Wallet`), installed by hand like the
Moment package. Provides the user **COIN wallet** (balance + a unified
`wallet_transactions` ledger), the **coin catalogue** (`coins` packages +
`payment_coins` groups), the **gateway purchase log** (`coin_logs`), and manual
`charges`. It **binds** the Base `App\Contracts\WalletContract` to its
`DatabaseWallet` implementation — the Base only ships the contract/facade/events/
NullWallet seam.

> Scope: COINS only. The dollar/earnings wallet + withdrawals live in the
> `target` package; diamonds in the `agency`/`gifts` packages. A dollar→coins
> conversion is recorded here as a `wallet_transactions` row of type `exchange`.

## Steps
1. **Autoload** — add to root `composer.json`:
   ```json
   "Utd\\Wallet\\": "packages/wallet/src/"
   // autoload-dev:
   "Utd\\Wallet\\Tests\\": "packages/wallet/tests/"
   ```
2. **Provider** — add to `config/app.php` providers (or rely on base package auto-discovery):
   ```php
   Utd\Wallet\Providers\WalletServiceProvider::class,
   ```
3. **Filament** — add to `app/Providers/Filament/AdminPanelProvider.php`:
   ```php
   ->plugin(\Utd\Wallet\Filament\WalletPlugin::make())
   ```
4. `composer dump-autoload && php artisan migrate`

## What it ships
- Migrations: `user_wallets`, `payment_coins`, `coins`, `coin_logs`, `wallet_transactions`, `charges`.
- `DatabaseWallet` (row-locked credit/debit + events), `ChargeService` (single charge entry point).
- API (auth): `GET /api/wallet/balances`, `GET /api/wallet/transactions?currency=`,
  `GET /api/coins`, `GET /api/coins/payment-methods`.
- Filament (group "Wallet"): Charges (list + create form) and Wallet Transactions (ledger).
- `CoinTransactionType` enum (ported from Eagle's UserCoinLogType) standardises `wallet_transactions.type`.
- Config `wallet` (enabled, default_currency = coins, currencies = [coins] — extensible).

## Depends on Base seam (not bundled — already in base-project)
`App\Contracts\WalletContract`, `App\Facades\Wallet`, `App\Support\Wallet\WalletResult`,
`App\Events\Wallet\{WalletCredited,WalletDebited}`, `App\Exceptions\{InsufficientFundsException,WalletProviderMissingException}`,
`App\Services\Wallet\NullWallet`, `App\Services\PackageRegistry`, `App\Helpers\Common`, `App\Filament\Resources\BaseResource`.
