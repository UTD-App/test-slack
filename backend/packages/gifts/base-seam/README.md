# base-seam — Base-owned integration points for the Gifts package

These files do **NOT** belong to the `Utd\Gifts` package itself — they live in the
**Base project** and the Gifts package binds their implementations. They are shipped
here only as a **drop-in reference**: when you install Gifts into a Base that does not
already have them, copy them into the Base at the paths below.

Why they stay in the Base (the "seam"): feature packages (Moment, Reels, Room…) send
and read gifts WITHOUT depending on the Gifts package — they resolve these contracts
from the container. The Base ships **no** default binding, so gifting stays gracefully
disabled until the Gifts package is installed and binds the implementations.

## Where each file goes in the Base

| This repo (base-seam)                                  | Base project path                                   |
| ------------------------------------------------------ | --------------------------------------------------- |
| `app/Contracts/GiftSender.php`                         | `app/Contracts/GiftSender.php`                      |
| `app/Contracts/GiftDirectory.php`                      | `app/Contracts/GiftDirectory.php`                   |
| `app/Contracts/LuckyGiftResolver.php`                  | `app/Contracts/LuckyGiftResolver.php`               |
| `app/Contracts/GiftBagProvider.php`                    | `app/Contracts/GiftBagProvider.php`                 |
| `app/Contracts/VipLevelProvider.php`                   | `app/Contracts/VipLevelProvider.php`                |
| `app/Events/Gifts/GiftSent.php`                        | `app/Events/Gifts/GiftSent.php`                     |
| (flutter) `../../flutter/base-seam/shared/gifts/gift_bridge.dart` | `flutter/lib/shared/gifts/gift_bridge.dart` |

Namespaces are already `App\Contracts` / `App\Events\Gifts`, so they drop in unchanged.

> **Keep in sync:** the `Utd\Gifts` package is compiled against these signatures. If
> you change a contract here, mirror it in the Base. `GiftSender` now declares BOTH
> `send()` (single receiver) and `sendMany()` (batch) — make sure the Base copy has both.

## What binds them

- `GiftSender`   → `Utd\Gifts\Services\GiftSendingService`   (spend coins → earn diamonds via Wallet; single + batch)
- `GiftDirectory`→ `Utd\Gifts\Services\GiftDirectoryService` (aggregation for Moment/Reels/…)
- `LuckyGiftResolver` → bound by the **lucky-gift plugin** — gift `type = lucky`. Unbound → lucky sends fail gracefully.
- `GiftBagProvider`   → bound by the future **backpack plugin** — used when a send has `context['source']='bag'`. Unbound → bag sends fail gracefully (coin sends unaffected).
- `VipLevelProvider`  → bound by the future **vip package** — enforces a gift's `vip_level`. Unbound → gate skipped.
- `GiftSent`     → fired by the package PER receiver; Agency/Levels/Ranking/Family/Room… listen without depending on Gifts.

## The `GiftSent` context contract (how feature packages re-create Eagle's effects)

The Gifts core does the money + log only. Everything Eagle layered on top is done by
**listeners of `GiftSent`** living in their own packages. The event carries
`(sender, receiver, giftId, quantity, total, earned, context)`. The **caller** (the
host feature controller) populates `context`; listeners read these keys:

| context key                         | used by (future package) | Eagle effect |
| ----------------------------------- | ------------------------ | ------------ |
| `type`, `id`                        | all                      | the context (moment/reel/room/live) |
| `room_id`, `room_type`, `roomowner_id` | Room                  | room session / room coins / room level / room-owner 3% |
| `agency_id`                         | Agency                   | agency split |
| `sender_family_id`, `receiver_family_id` | Family              | family level/rank + notify |
| `cp_id`                             | CP                       | couple level/gifts |
| `pk` (bool)                         | Room/PK                  | PK team scores + Zego |
| `batch_id`, `source`                | (added by the core)      | batch grouping; coins\|bag |

Sender/receiver level-ups, monthly/total diamond stats, diamond logs and the gift
banner are also `GiftSent` listeners (Levels/Stats/Broadcast packages).

See `../INSTALL.md` for the full install wiring.
