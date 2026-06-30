# Package-by-Package Review & Action Plan — test-stack

> ملخص بالعربي: راجعت كل باكدج لوحدها (backend + Flutter) + الـ base، وركّزت على
> **اللغة/الترجمة** هل متناسبة مع الـ base ولا لأ. الخلاصة: **معمارية الترجمة في الـ base
> ممتازة** (loader + registry + version-gate + overlay)، بس فيه **تفاوت كبير بين الباكدچات**:
> `wallet` و`reels` الأفضل، و`audio-room` الأسوأ (مفيش ترجمة backend خالص + ~55 نص إنجليزي
> ثابت + ثغرة أمان في توكن الـ Stream). تحت فيه scorecard لكل باكدج + خطة عمل P0/P1/P2.

Date: 2026-06-29 (updated 2026-06-30) · Scope: every package (backend `packages/*` + flutter `packages/*`) + base.
Method: 8 parallel read-only audits against the base i18n + architecture conventions.

---

## 0. Execution status (2026-06-30)

**P0, P1 and P2 are DONE for every package except `audio-room`** (left untouched by request)
and the CI-tooling items (left as recommendations). Verified green after each batch:
**backend 831 tests**, **Flutter 985 tests** (1 expected network-SVG skip).

| Batch | Commit | Status |
|---|---|---|
| P0 — security + install blockers | `a965283` | ✅ done (audio-room item deferred) |
| P1 — localization + contract consistency | `b4555ef` | ✅ done (audio-room items deferred) |
| P2 — quality + docs + cleanup | `2535655` | ✅ done (CI items deferred) |

🚫 **audio-room — NOT touched** (owner's call): Stream-token impersonation (P0), backend i18n
absence + hardcoded dialogs/plugins (P1), raw avatar URLs + dead dialogs/debugPrint (P2). All
its findings remain below for whoever owns it.
⏳ **Deferred (CI/infra, not code)**: translation key-drift CI check; `dependency_overrides`
duplication CI guard.

Legend below: ✅ done · 🚫 audio-room (skipped) · ⏳ deferred.

---

## 1. Scorecard (professional-readiness at a glance)

| Package | i18n vs base | Readiness | Biggest issue |
|---|---|---|---|
| **wallet** | ✅ consistent (both stacks, mirrored, Filament localized) | ★★★★☆ | No admin UI for the coin recharge catalogue |
| **reels** | ✅ consistent (4 lang groups, full parity, owner-scoping verified) | ★★★★☆ | Missing base middleware; unthrottled `seed` route |
| **gifts** | ✅ consistent (a few stray literals) | ★★★★☆ | **Stale vendored `gift_bridge` seam → fresh install won't compile** |
| **moment** | 🟡 partial (1 hardcoded error → English SnackBar) | ★★★☆☆ | Middleware gaps; latent type-2 liked-feed bug |
| **profile** | 🟡 partial (hardcoded badge labels; thin backend mirror) | ★★★☆☆ | Case-sensitivity bug breaks dashboard i18n on prod |
| **authentication** | ✅ near-perfect parity (3 minor leaks) | ★★★★☆ | `LoginModel.fromJson` hard casts crash on edge payloads |
| **utd_studio_sdk** | ✅ coherent `t.*` seam | ★★★★☆ | Hardcoded-Arabic "missing screen" placeholder |
| **audio-room** | ❌ inconsistent (no backend i18n at all) | ★★☆☆☆ | **Security: client-supplied Stream `identity` → impersonation** |
| **base** | architecture A- / content B- | ★★★★☆ | `CheckLatestToken` returns HTTP 505; `fallback_locale=ar` |

---

## 2. Language / localization — the focus

**The base i18n architecture is professional and coherent** — genuinely above-average:
backend `TranslationLoader` (lang-file scan + DB overlay, DB wins) → `TranslationGroupRegistry`
(package seam) → `GET /api/translations/{locale}` (+`/version`,`/supported`) → Flutter
`TranslationService` (version-gated fetch + Hive cache + offline fallback) overlaying shipped
const maps. Languages/RTL/native-names are admin-driven, not hardcoded.

**The convention every package is measured against:**
- Backend: ship `resources/lang/{ar,en}/<slug>.php`; register via `loadTranslationsFrom($dir,'<slug>')`
  **and** `TranslationGroupRegistry::register('<slug>',$dir)`; keys mirror the Flutter `<x>_strings.dart`
  map (prefix stripped); user-facing text via `__('<slug>.key')` — no bare literals; AR↔EN parity.
- Flutter: ship `<x>_strings.dart` (`static const k='<slug>.key'` + `translations()=>{'en':…,'ar':…}`),
  registered via the feature; widgets use `context.tr(XStrings.k)`; en/ar parity + matching tokens.

**Where packages diverge from the base (the language gaps):**
1. **audio-room (worst): no backend localization at all** — no `resources/lang/*`, no registration,
   ~55 hardcoded English literals across the 3 controllers; bare `$request->validate` (skips the 422
   convention). Flutter ~90% localized but has live hardcoded dialogs (`pip_permission_dialog`,
   `room_password_dialog`, `room_edit_text_sheet`, app-overlay ternaries) and 11/13 plugins ship
   English-only `displayName`s; charisma/emoji plugins use a private `_isAr` map that never registers
   into `context.tr`. One AR-only orphan key (`audio_room.recently_added`).
2. **Cross-stack mirror drift** (Flutter keys not served by backend → not admin-editable):
   profile ~32 keys, moment 5 keys (`more/less/share/new_moments/image_a11y`), gifts 3 dead keys.
3. **Stray hardcoded user-facing strings** (otherwise-localized packages): moment
   `moment_feed_bloc.dart:207`; gifts `GiftController.php:129` + `gift_api_service.dart:110` +
   quantity hint; profile badge chips (`profile_badges_row.dart`); authentication `Text('OK')` +
   `'، '` separator + resend `s`; studio_sdk `_missing` (hardcoded Arabic).
4. **Dynamic values never localized**: wallet ~45 `CoinTransactionType` labels; moment/reels
   `compactNumber` K/M (acceptable).
5. **profile uses a non-standard strings shape** (bare top-level `const Map` + raw `'profile.x'`
   literals) instead of the `XStrings` class pattern every sibling uses.
6. **Base content issues**: `api_responses.php` AR(188)≠EN(159) with legacy typo'd non-base keys
   (`try_agane_leter`, `sases_mute`, `u_not_in_fund`…); ~6 base controllers emit bare literals
   (`AuthController` logout/profile/avatar/settings messages, `StacController`, `UserController`,
   `PageController`, `MediaController`); `config/app.php fallback_locale='ar'` (missing-EN-key → Arabic).
7. **Cross-stack envelope key**: backend sends `status`, Flutter `BaseResponse`/`ApiResponse` read
   `success` → the body flag is dead (harmless today, HTTP-code-driven).

---

## 3. Consolidated action plan

### P0 — security / correctness / install-blocking (do first)  — ✅ done (`a965283`), audio-room deferred
- [ ] 🚫 **audio-room — fix Stream-token impersonation**: pin `'identity' => (string) Auth::id()` in
      `backend/packages/audio-room/.../RoomController.php:296` (ignore client `identity`). *(skipped — audio-room)*
- [x] ✅ **base — `CheckLatestToken` 505 → 401** + localized message (`messages.another_device_login`).
- [x] ✅ **base — middleware parity on package routes**: added `checkLatestToken, userBan,
      update.last.seen, localization` (and `generalBan` for reels) to moment + reels route groups.
- [x] ✅ **gifts — re-synced the stale seam** `gift_bridge.dart` (added `GiftRecipient`,
      `RoomGiftSentCallback`, room params) — fresh install compiles.
- [x] ✅ **authentication — hardened `LoginModel.fromJson`** (null/typed-variant coercion) + test.
- [x] ✅ **wallet — added Filament admin for `Coin` + `PaymentCoin`** (recharge catalogue) + test.
- [x] ✅ **base — `fallback_locale` `ar` → `en`**.

### P1 — localization completeness + contract consistency  — ✅ done (`b4555ef`), audio-room deferred
- [ ] 🚫 **audio-room — add backend i18n** (lang files + registration + replace ~55 literals). *(skipped — audio-room)*
- [ ] 🚫 **audio-room — localize live Flutter dialogs + plugin `displayName`s**. *(skipped — audio-room)*
- [x] ✅ **moment — localized** the post-error path (`empty_content`/`post_failed`).
- [x] ✅ **gifts — localized** 'user not found' + 'unsupported context'.
- [x] ✅ **profile — localized badge chips** + **fixed the `Resources/lang` casing bug** (prod-safe).
- [x] ✅ **authentication — localized** OK / list-separator / seconds-unit; **fixed the `status`/`success`
      envelope key** (now prefers `status`, falls back to `success`).
- [x] ✅ **studio_sdk — routed `_missing`** through the translate port (English fallback).
- [x] ✅ **base — `api_responses.php` AR↔EN parity** (no deletions; legacy keys flagged); ~11 base
      controller literals → `__()`.
- [x] ✅ **cross-stack mirror** — backend lang entries added (profile ~38, moment 5) → admin-editable.
- [x] ✅ **pagination meta** — gifts `history`/`userGifts` emit `meta`; moment feed consumes it
      (new `MomentPage`); NOTES_GAPS corrected. *(audio-room `->get()` lists deferred — 🚫)*
- [ ] 🚫 **media URLs** — raw avatar paths in audio-room controllers. *(skipped — audio-room)*

### P2 — quality / convention / cleanup  — ✅ done (`2535655`), audio-room + CI deferred
- [x] ✅ **doc convention** — bilingual `doc/about.html` + `doc/installation.html` shipped for gifts,
      moment, profile, reels, wallet, authentication, utd_studio_sdk. *(audio-room docs skipped — 🚫)*
- [x] ✅ **dead code** — profile (`profile_format.dart`+test, `ProfileHeader`), reels typo
      `deleteReeltAndReport`→`deleteReelAndReport` + `ReelReaction.label`, moment 5 dead keys +
      `MomentReaction.label`, gifts 3 dead keys, authentication `CheckEmailEvent`/`CheckEmailUseCase`.
      *(audio-room dead dialogs + `[MSG]` debugPrint skipped — 🚫)*
- [x] ✅ **profile — adopted the `ProfileStrings` class shape** (20 callsites).
- [x] ✅ **wallet — localized ~43 `CoinTransactionType` labels** (with fallback) + **transactions
      load-more** (`WalletTransactionPage`); stale `NOTES_GAPS.md` fixed.
- [x] ✅ **studio_sdk — gated `_log` `debugPrint` behind `kDebugMode`**. ⏳ *(CI guard for the
      `dependency_overrides` footgun deferred — infra.)*
- [x] ✅ **base — fixed the password double-hash footgun**: idempotent `setPasswordAttribute`
      (blank=keep, already-hashed=store as-is, plaintext=bcrypt) + test. *(Used a smart mutator instead
      of the `hashed` cast so the "blank = keep current" admin-edit behavior is preserved.)*
- [x] ✅ **moment — liked-feed (type 2) shape fix** (returns `Moment` models) + test.
      ⏳ *(translation key-drift CI check deferred — infra.)*

---

## 4. Execution log

All three batches were executed in order (audio-room excluded throughout), each verified green:

1. **P0** (`a965283`) — CheckLatestToken 401, moment/reels middleware parity, gifts seam re-sync,
   fallback_locale, LoginModel hardening, wallet Coin/PaymentCoin admin.
2. **P1** (`b4555ef`) — moment/gifts/profile/authentication/studio localizations, base controllers +
   `api_responses.php` parity, cross-stack mirror, envelope `status` key, pagination meta.
3. **P2** (`2535655`) — bilingual `doc/` for 7 packages, dead-code removal, profile `ProfileStrings`,
   wallet tx-label localization + load-more, studio debugPrint gate, base double-hash fix, moment
   type-2 fix.

**Still open (intentionally):**
- **audio-room** — every audio-room item above (P0 Stream-token impersonation is the priority). Left
  for its owner.
- **CI/infra** — translation key-drift check; `dependency_overrides` duplication guard.

Tests after the full run: **backend 831**, **Flutter 985** (+1 expected skip), 0 failures.
