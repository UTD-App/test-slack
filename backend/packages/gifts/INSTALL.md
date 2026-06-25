# Utd\Gifts — install (manual drop-in)

Standalone composer package (namespace `Utd\Gifts`), installed by hand like Wallet/Moment.
Depends on the **Wallet** package (spends `coins`, earns `diamonds`).

## Steps (in the Base project)

1. **Autoload** — root `composer.json`:
   ```json
   "Utd\\Gifts\\": "packages/utd/gifts/src/",
   "Utd\\Gifts\\Tests\\": "packages/utd/gifts/tests/"   // autoload-dev
   ```
2. **Provider** — `config/app.php` providers (after the Wallet provider):
   ```php
   Utd\Gifts\Providers\GiftsServiceProvider::class,
   ```
3. **Filament** — `app/Providers/Filament/AdminPanelProvider.php`:
   ```php
   ->plugin(\Utd\Gifts\Filament\GiftsPlugin::make())
   ```
4. **Wallet** — make sure `diamonds` is in `config('wallet.currencies')` (the receiver's earning currency).
5. Run:
   ```bash
   composer dump-autoload
   php artisan migrate
   php artisan db:seed --class="Utd\\Gifts\\Database\\Seeders\\GiftCatalogSeeder"   # optional starter gifts
   php artisan utd:sync-packages
   ```

## What lights up
- Binds `App\Contracts\GiftSender` → sending a gift works everywhere it's wired.
  **Moment** gifting (`POST /api/moment/{id}/gift`) returns 200 instead of 503 automatically.
  Supports a **single receiver** (`send`) and a **batch** of receivers in one call
  (`sendMany`, e.g. room/live) — one debit, one `batch_id`, a `gift_log` + a `GiftSent`
  event per receiver.
- Binds `App\Contracts\GiftDirectory` → Moment's `getGifts`/`userGift` + `gifts_count` show real data.
- Fires `App\Events\Gifts\GiftSent` (per receiver) for later packages (Room/Agency/Levels/Family…) to layer their effects.

## The send engine (parity with Eagle, mapped to the package world)
What the **core** does on every send: validate (enabled gift; optional VIP gate),
spend `coins` and earn `diamonds` via the **Wallet** (Eagle's `di`→`diamonds`), write a
`gift_logs` row per receiver, bump the gift's `use_count`, and fire `GiftSent`.

What is **delegated to optional seams** (graceful no-op while unbound):
- `type = lucky`           → `App\Contracts\LuckyGiftResolver`  (lucky-gift plugin)
- `context['source']='bag'`→ `App\Contracts\GiftBagProvider`   (backpack plugin)
- gift `vip_level`         → `App\Contracts\VipLevelProvider`   (vip package)

What is **deferred to GiftSent listeners** in their own packages (read the context
keys — see `base-seam/README.md`): room-owner/platform/agency split, family
level/rank, PK scores, CP, charisma, room session/coins/level, room boom,
sender/receiver levels + monthly/total diamond stats, diamond logs, gift banner.

## API (read-side, auth)
- `GET /api/gifts/categories`
- `GET /api/gifts?category_id=`
- `GET /api/gifts/history?type=sent|received`
- `GET /api/gifts/context/{type}/{id}` · `GET /api/gifts/context/{type}/{id}/gifters`

Sending has **no** gifts route (like Eagle): it happens through the host feature's
route (Moment now; Room/Live/Reels later) which resolves `GiftSender`.

## Stays in the Base (seam)
`App\Contracts\GiftSender` (now `send` + `sendMany`), `App\Contracts\GiftDirectory`,
`App\Contracts\LuckyGiftResolver`, `App\Contracts\GiftBagProvider`,
`App\Contracts\VipLevelProvider`, `App\Events\Gifts\GiftSent`. This package binds
`GiftSender`/`GiftDirectory`; the others are bound by their own plugins/packages.
See `base-seam/` for drop-in copies.

## Deferred (plugins / later)
Lucky gifts (FairLuck) → `lucky-gift` plugin binds `LuckyGiftResolver`. Bag/backpack →
backpack plugin binds `GiftBagProvider`. VIP gate → vip package binds `VipLevelProvider`.
CP gifts → CP package. Room-owner/agency/family/levels/diamond splits → their packages
(via `GiftSent`). Room/Live/Chat gifting → reuse this same engine with a different `$context`.
