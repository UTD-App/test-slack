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

Second cleanup pass (`d4956b1`) closed the low-severity items below:
- ✅ reels — `reals/seed` route now throttled (`throttle:5,1`).
- ✅ gifts — quantity hint localized (`gifts.quantity_hint`). The `GiftDirectoryService` raw-vs-absolute
  split turned out to be **already documented** per-method (intentional, for Flutter `resolveMediaUrl`) — left as-is.
- ✅ base (flutter) — the last hardcoded UI strings (`home_screen`/`app_shell`/`ui_slot_renderer`) localized.
- ✅ profile — unused `mini_profile_card` stub registration removed.

Still open — **deliberately left** (change riskier than the benefit) + infra + audio-room:
| Package | Open item | Why left | Severity |
|---|---|---|---|
| moment | `gifts_count`/`gifts_coins` N+1 in `MomentResource` | needs a batch method on the `GiftDirectory` seam; fine at 10/page | low (perf) |
| moment | `MomentCommint` entity / `Reporter_id` column typos | renaming touches the DB schema + many refs for zero behavior gain | cosmetic |
| base | legacy `api_responses` keys (flagged, not deleted) | packages may still reference them — needs a careful per-key migration | low |
| base | `UtdManifestController` hand-rolled JSON envelope | by design (Studio design-time contract) | n/a |
| CI/infra | translation key-drift check; `dependency_overrides` guard | CI wiring, not code | ⏳ infra |
| **audio-room** | **all of it** (Stream-token impersonation is the priority) | not touched by request | 🚫 owner |

Everything else from the audits has been fixed (see commits in the action plan + `d4956b1`).

---

## Verification pass #2 — 2026-06-30 (adversarial re-audit + hardening)

To gain confidence beyond the test counts, I ran **4 parallel read-only adversarial audits** over every non-audio-room package, each on a high-risk dimension, then fixed only what was real and verified it with new regression tests.

**Audit results (what was attacked):**
- **Authorization / IDOR / impersonation / mass-assignment / SQLi** — *clean.* Every mutating route is `auth:sanctum`-gated; every ownership-keyed delete/update checks `Auth::id()`; writes derive identity server-side (no impersonation); `User` and wallet models exclude sensitive columns from mass-assignment; no raw-input SQL. One **P2 informational** only: gift *aggregate* leaderboards (`/my_gifts?user_id=`, `/gifts/context/*`) are readable for any id — read-only, non-private, intentional.
- **Wallet / gifts money path** — *sound.* `DatabaseWallet::move()` is `DB::transaction` + `lockForUpdate`, atomic ledger writes, bcmath on `decimal(20,2)`, `unique` idempotency keys (double-guarded in the gift layer), `assertPositive`, room-owner cut pinned to the room (never client `owner_id`). No value-create/destroy bug.
- **Input validation** — the "must use CValidationException" premise is now **moot**: `Handler` renders plain `ValidationException` as 422 on `api/*` (concurrent fix). Real findings were a cluster of **unvalidated free-text → guaranteed 500** + one uncapped paginator (fixed below).
- **Flutter JSON-parse crashes** — model layers are mostly hardened already; the residual was a **P1 launch-path crash** in the base `MyDataModel` chain (fixed below).

**Fixes applied this pass:**
| # | Sev | Package | Fix | Tests |
|---|---|---|---|---|
| 1 | P1 | base (flutter) | `MyDataModel`/`ProfileRoomModel`/`CountryModel`/`BaseResponse` now coerce primitives (new shared `coerceInt` + `?.toString()` + tolerant bool). The cached **offline-launch** path parses outside any try/catch, so a server/cache type-drift used to crash the app on start. | +5 |
| 2 | P2 | moment | Comment `store` now trims + rejects empty/over-255 (NOT-NULL VARCHAR(255)) — mirrors reels. Was a guaranteed **500**. New `content_too_long` key (en/ar). | +2 |
| 3 | P2 | gifts | `gifts/history` `per_page` clamped to `[1,100]` (matches WalletController) — row-count DoS. | +1 |
| 4 | P2 | moment + reels | Report `description`/`type` length-capped to the actual column size (VARCHAR 255) before insert — prevented **500** on over-length report payloads (4 endpoints). | covered |

**Still NOT changed (unchanged rationale):** the deliberately-left items table above (moment N+1, `MomentCommint` typo, legacy `api_responses` keys, `UtdManifest` envelope, CI guards) and **all of audio-room**.

**Verified:** backend **834** tests / Flutter **990** (+1 skip), 0 failures · `dart analyze` clean on all changed files.

---

## Verification pass #3 — 2026-06-30 (closing the deliberately-left items)

Went back through the "deliberately left" table and **did the ones that are genuine improvements**, while consciously **keeping** the ones whose change is riskier than the (zero) functional benefit.

**Done:**
| Item | What changed | Verified |
|---|---|---|
| moment **N+1** | Added `GiftDirectory::statsFor(type, ids)` (one grouped query for a whole page) + `GiftDirectoryService` impl + base-seam contract sync (+`receiversFor`). `MomentRepository::hydrateReactions` now pre-computes `gifts_count_pre`/`gifts_coins_pre` per page (mirrors the reactions batch); `MomentResource` reads them, single-moment show still falls back. **2 queries/moment → 1 query/page.** | +1 feed test |
| **`MomentCommint`** typo | Renamed class → `MomentComment` (+ file) and the related `MomentCommmintResource` → `MomentCommentResource` (+ file), 14 files. Table name unchanged (`$table` explicit) → **no DB migration, no schema risk.** | 183 pkg tests |
| translation **key-drift** (was CI/⏳) | Added `TranslationParityTest` (Unit suite): asserts EN↔AR key parity across **every** lang group (base + each package). **It immediately caught real cruft** — a stray `app.hello` key in AR `app.php` not present in EN — now removed. | +1, green |
| `api_responses` legacy keys | Audited: **0 missing** referenced keys (no raw-key leaks) and **no dynamic refs**; EN↔AR parity now enforced by the test above. | (see below) |

**Kept on purpose (change riskier than the nil benefit):**
| Item | Why kept |
|---|---|
| `Reporter_id`/`Reported_id` column casing | Pure casing; renaming = an irreversible migration on deployed moderation tables (4 tables) for **zero** functional gain. DBAL is present so it's *possible*, but not worth the prod risk. |
| 158 legacy `api_responses` keys | Harmless when present; they belong to **Eagle-ecosystem packages not installed here** (families/agencies/mic) that consume them on assembly. Deleting risks the broader platform; the audit explicitly flagged "packages may reference them." |
| `UtdManifestController` raw envelope | Confirmed **by-design**: it implements the UTD Studio integration contract (`INTEGRATION.md §2–3`) — wrapping it in `Common::apiResponse` would break Studio. |
| **audio-room** (everything) | Excluded by request. |

**Verified:** backend **836** tests / Flutter **990** (+1 skip), 0 failures. Line-ending noise from the bulk rename (`sed -i` flips CRLF→LF on every file it touches) was cleaned up — the commit carries **only** real content changes.
