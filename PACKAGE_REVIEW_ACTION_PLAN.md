# Package-by-Package Review & Action Plan — test-stack

> ملخص بالعربي: راجعت كل باكدج لوحدها (backend + Flutter) + الـ base، وركّزت على
> **اللغة/الترجمة** هل متناسبة مع الـ base ولا لأ. الخلاصة: **معمارية الترجمة في الـ base
> ممتازة** (loader + registry + version-gate + overlay)، بس فيه **تفاوت كبير بين الباكدچات**:
> `wallet` و`reels` الأفضل، و`audio-room` الأسوأ (مفيش ترجمة backend خالص + ~55 نص إنجليزي
> ثابت + ثغرة أمان في توكن الـ Stream). تحت فيه scorecard لكل باكدج + خطة عمل P0/P1/P2.

Date: 2026-06-29 · Scope: every package (backend `packages/*` + flutter `packages/*`) + base.
Method: 8 parallel read-only audits against the base i18n + architecture conventions.

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

### P0 — security / correctness / install-blocking (do first)
- [ ] **audio-room — fix Stream-token impersonation**: pin `'identity' => (string) Auth::id()` in
      `backend/packages/audio-room/.../RoomController.php:296` (ignore client `identity`).
- [ ] **base — `CheckLatestToken` 505 → 401** (`app/Http/Middleware/CheckLatestToken.php:39`) and
      localize the message; 505 breaks proxies/clients that branch on status class.
- [ ] **base — middleware parity on package routes**: add `checkLatestToken, userBan,
      update.last.seen, localization` (and `generalBan` for reels) to `packages/moment/routes/api.php:20`
      and `packages/reels/routes/api.php:54` — today a banned/superseded user bypasses via these routes.
- [ ] **gifts — re-sync stale seam** `flutter/packages/gifts/base-seam/shared/gifts/gift_bridge.dart`
      from the live `flutter/lib/shared/gifts/gift_bridge.dart` (missing `GiftRecipient`,
      `RoomGiftSentCallback`, room params) — a fresh install currently won't compile.
- [ ] **authentication — harden `LoginModel.fromJson`** (`login_model.dart:13-21`): defensive
      coercion for `id/is_first/auth_token` so an edge payload fails cleanly instead of crashing.
- [ ] **wallet — add Filament admin for `Coin`/`PaymentCoin`** so the recharge catalogue served by
      `CoinController` is manageable (today coin packages need raw DB).
- [ ] **base — `fallback_locale` `ar` → `en`** (`config/app.php:143`).

### P1 — localization completeness + contract consistency (professional polish)
- [ ] **audio-room — add backend i18n**: create `resources/lang/{en,ar}/audio-room.php` mirroring the
      Flutter `audio_room.*` map, register it, and replace all ~55 controller literals with `__()`.
- [ ] **audio-room — localize live Flutter dialogs** (pip permission, room password, edit-text sheet,
      app-overlay) and the 13 plugin `displayName`s; migrate charisma/emoji to `context.tr`.
- [ ] **moment — localize** `moment_feed_bloc.dart:207` ("Cannot post empty content"/"Failed to post").
- [ ] **gifts — localize** `GiftController.php:129` ('user not found') + `gift_api_service.dart:110`.
- [ ] **profile — localize badge chips** (`profile_badges_row.dart`) and **fix the casing bug**
      `'/resources/lang'`→`'/Resources/lang'` in `ProfileServiceProvider.php:34` (breaks dashboard i18n on prod).
- [ ] **authentication — localize** `Text('OK')`, the `'، '` join, and resend `s`; fix the
      `status`/`success` envelope key in `base_response.dart:36` + `api_response.dart:52`.
- [ ] **studio_sdk — route `_missing` through the translate port** (`stac_dynamic_screen.dart:121`).
- [ ] **base — reconcile `api_responses.php`** to AR↔EN parity, purge legacy/typo'd non-base keys into
      the owning packages; replace bare literals in the ~6 base controllers with `__()` keys.
- [ ] **cross-stack mirror** — add backend lang entries for the Flutter-only keys (profile ~32,
      moment 5) so they become admin-editable.
- [ ] **pagination meta** — emit `meta` for gifts `history`/`userGifts` (pass paginator as the 5th
      `apiResponse` arg) and consume backend `meta` in moment's `moment_api_service` (+ fix stale
      NOTES_GAPS claims); add meta (or document non-paged) on audio-room `->get()` lists.
- [ ] **media URLs** — resolve raw avatar paths to absolute in audio-room `RoomController.php:391`,
      `RoomAdminController.php:27,104` (and `country_flag`).

### P2 — quality / convention / cleanup
- [ ] **doc convention — ALL packages**: ship bilingual `doc/about.html` + `doc/installation.html`
      (currently **missing in every package**, backend and flutter).
- [ ] **dead code**: profile (`profile_format.dart`, `ProfileHeader`), reels typo `deleteReeltAndReport`,
      moment dead keys + `MomentReaction.label`, gifts 3 dead keys, audio-room dead dialogs +
      `[MSG]` debugPrint, authentication unused `CheckEmailEvent`.
- [ ] **profile — adopt the `XStrings` class shape** for `profile_strings.dart` (match siblings).
- [ ] **wallet — localize `CoinTransactionType` labels** + implement transactions load-more (backend
      already paginates); fix stale `NOTES_GAPS.md`.
- [ ] **studio_sdk — gate `_log` `debugPrint` behind `kDebugMode`**; add a CI check for the
      `dependency_overrides` duplication footgun.
- [ ] **base — guard the password double-hash footgun** (`User::setPasswordAttribute`): add the
      `'password' => 'hashed'` cast OR a "don't pass pre-hashed values" guard/test.
- [ ] **base — CI key-drift check** between backend `app` lang group and Flutter `base_translations.dart`;
      moment liked-feed (type 2) shape fix before enabling that tab.

---

## 4. Suggested execution order

1. **Security & install blockers (P0)** — one short PR: audio-room identity pin, CheckLatestToken 401,
   middleware parity, gifts seam re-sync, fallback_locale, LoginModel hardening, wallet Coin admin.
2. **Localization sweep (P1)** — package by package, starting with **audio-room backend i18n** (the
   only package failing the convention outright), then the stray-literal fixes + mirror completion +
   `api_responses.php` cleanup. This is the bulk of "make it professional / language consistent."
3. **Convention & cleanup (P2)** — the universal `doc/` rollout, dead-code removal, and the
   hardening/CI guards.

Each item above has a concrete file reference; tackle P0 as a batch, then P1 per-package.
