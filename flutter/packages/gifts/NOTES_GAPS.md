# Gifts (Flutter) — scope & deferred pieces

Mirrors the **core** of the big app's gifting: a catalog + a send picker + history.
Spends sender coins, the receiver earns diamonds (handled by the backend).

## In scope (built)
- **Gift picker** (`GiftPickerSheet`) — category tabs + gift grid + quantity + send.
  Opened from any host feature via the host `GiftBridge` (no compile dependency).
- **Moment gifting**: the moment card shows a gift button (when Gifts is installed)
  that opens the picker for that moment; sending posts to `POST /api/moment/{id}/gift`.
- **Gift history** page (received / sent) at route `/gifts/history` (also in the drawer).
- Hidden when the backend `gifts` package is disabled (`packageSlug: 'gifts'`).

## How the cross-package wiring works
- Host app seam: `lib/shared/gifts/gift_bridge.dart` (`GiftBridge`) — the Flutter
  analog of the backend `App\Contracts\GiftSender`.
- `GiftsFeature.initialize()` registers the launcher; hosts call
  `GiftBridge.instance.open(context, contextType: 'moment', contextId: id)`.
- The picker maps `contextType` → host endpoint (`moment` → `/moment/{id}/gift`,
  `real`/`reel` → `/reals/{id}/gift`).

## Deferred (later / plugins)
- **Lucky gifts** (probability/combo UI) → with the `lucky-gift` plugin.
- **Gift animations** (svga/mp4/lottie playback on receive) — needs a room/live
  surface; the picker shows static thumbnails for now.
- **Multi-recipient** send (all-on-mic) → with Room/Live.
- **Coin balance** display in the picker — could read the Wallet package later.
- Showing the received-gifts row on a moment detail (uses
  `GET /api/gifts/context/moment/{id}`) — endpoint ready; UI is a follow-up.
