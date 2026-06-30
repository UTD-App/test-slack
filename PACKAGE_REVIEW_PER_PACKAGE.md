# Per-Package Problem Report — test-stack

> ملخص: ده تقرير **لكل باكدج لوحدها** — المشاكل اللي اتلاقت في كل واحدة + حالتها دلوقتي.
> الرموز: ✅ = اتصلّح · 🟡 = لسه مفتوح (بسيط/P2) · 🚫 = audio-room (مسيبينها لصاحبها) · ⏳ = مؤجّل (CI/infra).
> اللي اتصلّح كله متحقّق منه: backend **831** test · Flutter **985** test (+1 skip) · 0 failures.

Date: 2026-06-30 · Source: 8 parallel read-only audits → fixes in commits `a965283` (P0),
`b4555ef` (P1), `2535655` (P2). audio-room intentionally untouched.

---

## wallet — i18n ✅ consistent · readiness ★★★★ (best)
- ✅ No admin UI for the coin recharge catalogue → added Filament `Coin` + `PaymentCoin` resources (+test).
- ✅ ~43 `CoinTransactionType` labels never localized → added `wallet.tx_type.*` (en/ar, with fallback).
- ✅ Transactions were first-page only → load-more pagination (`WalletTransactionPage`).
- ✅ Missing bilingual `doc/` → shipped. ✅ Stale `NOTES_GAPS.md` (dollar/UiSlot) → fixed.
- Backend was already fully localized (Filament + API), bcmath money precision, idempotent ledger — solid.

## reels — i18n ✅ consistent · readiness ★★★★
- ✅ Missing base middleware (checkLatestToken/userBan/generalBan/update.last.seen/localization) → added.
- ✅ Source typo `deleteReeltAndReport` → renamed `deleteReelAndReport`. ✅ Dead `ReelReaction.label` → removed.
- ✅ Missing bilingual `doc/` → shipped.
- 🟡 **Open:** dev `reals/seed` route sits OUTSIDE the throttle + `package.enabled` group (can be hit
  unthrottled while the package is disabled). Low risk (env-gated + key) — left as a follow-up.
- Strongest i18n (4 lang groups at parity); owner-scoping (IDOR) verified clean. No P0.

## gifts — i18n ✅ consistent · readiness ★★★★
- ✅ **Install blocker**: stale vendored `gift_bridge.dart` seam → re-synced (fresh install compiles).
- ✅ Hardcoded 'user not found' (`GiftController:129`) + 'Unsupported gift context' → localized.
- ✅ `history`/`userGifts` didn't emit pagination `meta` → fixed. ✅ 3 dead label-keys → removed.
- ✅ Missing bilingual `doc/` → shipped.
- 🟡 **Open:** quantity hint `'1 – 9999'` hardcoded (`gift_picker_sheet.dart`). Cosmetic.
- 🟡 **Open:** `GiftDirectoryService` returns RAW media paths in `topSupporters`/`groupedGiftsByColumn`
  while sibling methods return absolute URLs (works today via `resolveMediaUrl`; latent footgun — document or unify).

## authentication — i18n ✅ near-perfect · readiness ★★★★
- ✅ **`LoginModel.fromJson` hard casts** crashed on edge payloads → hardened (+test).
- ✅ 3 hardcoded leaks (`Text('OK')`, `'، '` join, resend `s`) → localized.
- ✅ Envelope `status`/`success` mismatch → parser now prefers `status`.
- ✅ Dead `CheckEmailEvent`/`CheckEmailUseCase` → removed; ✅ `recover_password` barrel export added.
- ✅ Missing bilingual `doc/` → shipped.
- 🟡 **Note:** no tests INSIDE the package — but it's covered externally under the app's `test/pkg/authentication` (56 tests).

## utd_studio_sdk — i18n ✅ coherent · readiness ★★★★
- ✅ Hardcoded-Arabic "missing screen" placeholder → routed through the translate port (English fallback).
- ✅ Ungated coercion `debugPrint` → gated behind `kDebugMode`.
- ✅ Missing bilingual `doc/` → shipped (with a prominent `dependency_overrides` warning).
- ⏳ **Deferred (CI):** a guard that fails loudly when an app entrypoint forgets the vendored-stac
  `dependency_overrides` (currently only documented).

## moment — i18n ✅ (was 🟡) · readiness ★★★ → ★★★★
- ✅ Hardcoded post-error path (`moment_feed_bloc.dart`) → localized.
- ✅ Cross-stack drift (5 Flutter keys not in backend) → mirrored. ✅ Pagination `meta` now consumed (`MomentPage`).
- ✅ Missing base middleware → added. ✅ **Latent type-2 liked-feed shape bug** → fixed (+test).
- ✅ 5 dead keys + `MomentReaction.label` → removed. ✅ Missing bilingual `doc/` → shipped.
- 🟡 **Open:** `gifts_count`/`gifts_coins` issue one query PER moment in `MomentResource` (N+1; fine at
  10/page, not batched). 🟡 cosmetic: misspelled `MomentCommint` entity/`Reporter_id` columns.

## profile — i18n ✅ (was 🟡) · readiness ★★★ → ★★★★
- ✅ **Case-sensitivity bug** (`/resources/lang` vs `/Resources/lang`) that silently broke dashboard
  i18n on prod → fixed.
- ✅ Hardcoded badge chips ('Agency'/'VIP'/'BD'…) → localized. ✅ Cross-stack mirror (~38 keys) → added.
- ✅ Non-standard strings shape → adopted `ProfileStrings` class (20 callsites).
- ✅ Dead `profile_format.dart` + `ProfileHeader` → removed. ✅ Missing bilingual `doc/` → shipped.
- 🟡 **Open:** `mini_profile_card` is registered with placeholder args (`userId:0, name:''`) — a
  non-functional stub unless a host overrides props.

## base (backend app + flutter lib) — i18n architecture A- / content fixed
- ✅ `CheckLatestToken` returned **HTTP 505** for a superseded token → now **401** (+ localized).
- ✅ Authed middleware stack diverged in moment/reels → restored parity.
- ✅ `fallback_locale = ar` → `en`. ✅ `api_responses.php` AR↔EN parity (no deletions). ✅ ~11 V1
  controller bare literals → `__()`. ✅ Flutter `BaseResponse`/`ApiResponse` envelope key → `status`.
- ✅ **Password double-hash footgun** (`User::setPasswordAttribute`) → idempotent mutator (+test).
- 🟡 **Open:** Flutter base has a few hardcoded UI strings bypassing `context.tr` — `home_screen.dart`
  ('Home'/'Menu'/'coming soon'), `app_shell.dart`, `ui_slot_renderer.dart` ('No features available').
  (Small handful; not yet routed through `app.*` keys.)
- 🟡 **Open (by design):** `UtdManifestController` Studio endpoints hand-roll their JSON (not `Common`),
  and `api_responses.php` still carries legacy/typo'd Eagle keys (flagged, not deleted — packages may reference them).
- ⏳ **Deferred (CI):** key-drift check between backend `app` lang group and Flutter `base_translations.dart`.

## 🚫 audio-room — i18n ❌ inconsistent · readiness ★★ (NOT touched — owner's call)
Everything below is **open** by request:
- 🚫 **Security (P0): client-supplied Stream `identity`** forwarded into the token → user impersonation
  (`RoomController.php:296`). Should pin to `Auth::id()`.
- 🚫 **No backend i18n at all**: no `resources/lang/*`, no registration, ~55 hardcoded English literals
  across the 3 controllers; bare `$request->validate` (skips the 422 convention).
- 🚫 Flutter ~90% localized but live hardcoded dialogs (pip permission, room password, edit-text sheet,
  app-overlay ternaries, message mention) + 11/13 plugins ship English-only `displayName`; charisma/emoji
  use a private `_isAr` map that never registers into `context.tr`; AR-only orphan `recently_added`.
- 🚫 Raw avatar paths (404 on GCS) in `RoomController::users`, `RoomAdminController::index`/`blacklist`.
- 🚫 No pagination `meta` on `->get()` list endpoints; dead `shared/room_password_dialog.dart` +
  duplicate exit dialogs + `[MSG]` debugPrint; missing bilingual `doc/`.

---

## Remaining open (non-audio-room) — quick list
| Package | Open item | Severity |
|---|---|---|
| reels | `reals/seed` route outside throttle/`package.enabled` group | low |
| gifts | quantity hint hardcoded; `GiftDirectoryService` raw-vs-absolute media split | low |
| moment | `gifts_count`/`gifts_coins` N+1 in `MomentResource`; `MomentCommint` typo | low / cosmetic |
| profile | `mini_profile_card` placeholder stub registration | low |
| base (flutter) | a few hardcoded UI strings (`home_screen`/`app_shell`/`ui_slot_renderer`) | low |
| base | legacy `api_responses` keys flagged (not migrated); `UtdManifest` raw envelope (by design) | low |
| CI/infra | translation key-drift check; `dependency_overrides` guard | ⏳ infra |
| **audio-room** | **all of it** (Stream-token impersonation is the priority) | 🚫 owner |

Everything not in this table from the audits has been fixed (commits above).
