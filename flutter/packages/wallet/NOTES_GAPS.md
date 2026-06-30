# Wallet (Flutter) — scope & deferred pieces

This package mirrors the **wallet portion** of the big app's coins page. The big
app's wallet screen is actually a composite of several packages; this one owns
only what the `utd/wallet` backend owns: **COINS only**. (The dollar/earnings
wallet + withdrawals live in the `target` package; diamonds in the
`agency`/`gifts` packages.)

## In scope (built)
- **Coin balance** (`GET /api/wallet/balances`).
- **Transaction history** with a date-range filter and localized type labels
  (`GET /api/wallet/transactions?currency=&start_date=&end_date=&type=&page=`),
  with **load-more pagination** driven by the backend `meta.has_more` flag
  (infinite scroll on the wallet page).
- Reached from `UiSlot.userProfile` (coin card on the user's own profile) and
  `UiSlot.drawer` (home menu). Route: `/wallet`. Hidden automatically when the
  backend `wallet` package is disabled (`packageSlug: 'wallet'`).

## Placeholders (locked "coming soon" — owned by other packages)
- **Recharge** (buy coins, packages, payment gateways, Google Pay) → `payment` package.
- **Exchange** (diamonds → coins/dollars) and the **Diamond** tab/balance → `agency` package.
- **Withdraw** (cash-out, `held` balance) → `withdrawal` package.

When those packages ship, they should replace the placeholders by contributing
to the wallet screen (e.g. via UI slots) rather than being added here.

## Deferred within this package
- **Rich counterparty** on transfer/gift rows (name/avatar of the other user) —
  needs the reference models (gifts/transfer) to exist first; today we show the
  localized transaction-type label (`wallet.tx_type.*`), falling back to the
  humanized `reason`/`type`.
- **Peer-to-peer transfer** (the big app's "giving/receiving") — not exposed by
  the backend yet; likely a `gifts`/transfer concern.
