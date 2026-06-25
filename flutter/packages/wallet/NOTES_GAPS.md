# Wallet (Flutter) — scope & deferred pieces

This package mirrors the **wallet portion** of the big app's coins page. The big
app's wallet screen is actually a composite of several packages; this one owns
only what the `utd/wallet` backend owns:

## In scope (built)
- **Two balances**: `coins` + `dollar` (`GET /api/wallet/balances`).
- **Transaction history** per currency with a currency switch and a date-range
  filter (`GET /api/wallet/transactions?currency=&start_date=&end_date=&type=`).
- Reached from `UiSlot.userProfileActions` (profile app bar icon) and
  `UiSlot.drawer` (home menu). Route: `/wallet`. Hidden automatically when the
  backend `wallet` package is disabled (`packageSlug: 'wallet'`).

## Placeholders (locked "coming soon" — owned by other packages)
- **Recharge** (buy coins, packages, payment gateways, Google Pay) → `payment` package.
- **Exchange** (diamonds → coins/dollars) and the **Diamond** tab/balance → `agency` package.
- **Withdraw** (cash-out, `held` balance) → `withdrawal` package.

When those packages ship, they should replace the placeholders by contributing
to the wallet screen (e.g. via UI slots) rather than being added here.

## Deferred within this package
- **Load-more pagination** for transactions (currently first page, `per_page`=20).
- **Rich counterparty** on transfer/gift rows (name/avatar of the other user) —
  needs the reference models (gifts/transfer) to exist first; today we show
  `reason` + `type`.
- **Peer-to-peer transfer** (the big app's "giving/receiving") — not exposed by
  the backend yet; likely a `gifts`/transfer concern.
