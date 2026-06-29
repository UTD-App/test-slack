# Test Coverage & Findings — test-stack (backend + Flutter)

> ملخص بالعربي: عملت tests شاملة للمشروع كله — الـ backend (endpoints + services +
> models + middleware + كل باكدج داخلياً) والـ Flutter (base + كل باكدج).
> **الإجمالي النهائي: 825 backend test + 978 Flutter test (1 skipped) = كلهم ناجحين.**
> لقينا **4 bugs**: 3 منهم **اتصلّحوا** (null-safety في notifications + profile badges،
> و cursor-pagination)، وواحد (double-hash للباسوورد) متوثّق ومتساب لقرار المنتج.

Date: 2026-06-29
Scope: the WHOLE app — every HTTP endpoint, base services/models/middleware/support,
each package's internal logic (services/models/listeners), plus the Flutter base and
every Flutter package (`audio-room`, `gifts`, `moment`, `profile`, `reels`, `wallet`,
`authentication`, `utd_studio_sdk`).

## Grand totals

| Suite | Tests | Result |
|---|---:|---|
| **Backend** (`php vendor/bin/phpunit`) | **825** | OK, 0 failures |
| **Flutter** (`flutter test`) | **978** (+1 skipped) | All passed |

Bugs found: **4** — fixed: notification `id`/`data` casts, `UserProfileModel.badges`
cast, `Common::paginationMeta` cursor crash; documented-only: `User` password
double-hash (load-bearing, needs a product decision). Details at the end.

The sections below detail the original endpoint pass first, then the deep coverage.

---

## TL;DR

| | Endpoints | Already tested | Tests added this pass |
|---|---:|---:|---:|
| **Core** (`routes/api.php`) | ~46 | 9 | **51** |
| audio-room | 38 | 5 | **53** |
| gifts | 12 | 9 | **8** |
| moment | 16 | 6 | **22** |
| reels | 20 | 11 | **24** |
| profile | 1 | 0 | **4** |
| wallet | 4 | 4 | 0 (already full) |
| **Total** | **~137** | | **+162 tests** |

**Full suite result:** `php vendor/bin/phpunit` → **350 tests, 1108 assertions, OK (0 failures)**.

**Endpoint bugs found: NONE.** Every endpoint returns the documented status code,
the standard `{status, message, data}` envelope, correct validation (422), correct
auth gating (401), ownership/authorization (403), and not-found (404).

---

## How to run

```bash
cd backend
php vendor/bin/phpunit --no-coverage                 # everything (350)
php vendor/bin/phpunit tests/Feature/Coverage        # new core endpoint tests
php vendor/bin/phpunit packages/<pkg>/tests          # a single package
```

Tests use an isolated in-memory SQLite DB (`phpunit.xml` → `DB_DATABASE=:memory:`,
`RefreshDatabase`), so they never touch the local MySQL data.

---

## New test files

Core (`tests/Feature/Coverage/`):
- `AuthEndpointsTest.php` — register, login (correct contract), check-email,
  logout, account/delete, all-countries, roles, email-OTP recovery (send/verify/reset).
- `UserEndpointsTest.php` — users/search, users/{id}, online-status, profile/avatar,
  settings get/update, configs.
- `DiscoveryEndpointsTest.php` — packages/installed, packages/register, menu(+version),
  page/{key}, stac/{name}(+version), stac/packages, stac/screens, utd/manifest,
  utd/translations (pull + write-back), utd sample. Covers the `utd.secret`/`stac.auth`
  guards (dev-mode allow + 401 paths).
- `NotificationPreferencesTest.php` — PUT notifications/preferences.

Packages:
- `packages/audio-room/tests/Feature/EndpointCoverageTest.php` (53) — full Room CRUD,
  actions, admin/blacklist, charisma, stream webhook. `rooms/{id}/token` uses
  `Http::fake()` (no real UTD Stream call) and asserts the server secret never leaks
  into the error envelope.
- `packages/gifts/tests/Feature/EndpointCoverageTest.php` (8) — history, context gifts,
  context gifters, group auth.
- `packages/moment/tests/Feature/EndpointCoverageTest.php` (22) — show/destroy,
  userMoments, comment index/react/report/destroy, like index, gift reads.
- `packages/reels/tests/Feature/EndpointCoverageTest.php` (24) — seed, user/my/followers
  reels, show/destroy/update, comment + like sub-resources, ownership scoping.
- `packages/profile/tests/Feature/EndpointCoverageTest.php` (4) — `GET users/{id}/profile`
  (this package previously had **zero** tests).

---

## Notes & optional improvements (no action required to ship)

These are NOT endpoint bugs. They are small hardening/quality items surfaced while
writing the tests.

1. **`POST /api/auth/login` returns `422` for wrong credentials, not `401`.**
   This is the project's deliberate convention (every auth failure → `422` +
   `{status:false}` envelope) and the base test documents it as intended. Purely a
   REST-semantics nicety: `401 Unauthorized` is the conventional code for bad
   credentials. Low priority; changing it is an API-contract change for the app.

2. **`User::setPasswordAttribute` always `bcrypt()`s its input (latent double-hash).**
   `app/Models/User.php` hashes on every assignment with no "already hashed" guard.
   No current endpoint trips this (registration/reset assign plaintext), but any
   future code that assigns an already-hashed value will double-hash and lock the
   user out. Consider guarding: `if ($value && !password_get_info($value)['algo']) {…}`
   or use Laravel's `casts` `'password' => 'hashed'`.

3. **Testing note — Sanctum guard caching across tokens in ONE feature test.**
   `StatefulGuard` caches the first resolved user within a single test process, so a
   later request sent with a *different* bearer can still resolve the first user. When
   a test switches acting users to verify ownership scoping, call
   `$this->app['auth']->forgetGuards()` between requests (production is unaffected —
   each HTTP request is a fresh process). Used in the reels coverage test.

4. **Process note — stale working-tree test copies during this run.**
   At the start of this pass, three base test files (`AuthApiTest`, `StacApiTest`,
   `TranslationApiTest`) existed in the working tree as **older, pre-fix copies**
   (asserting a non-existent `success` key + a double-hashed login password), which is
   why an initial run reported 7 failures. Those exact issues were already fixed in
   git (`df2885a "fix stale base Feature tests"`); the working tree was snapped back
   to the committed (correct) versions during the run, after which all pass. Nothing
   was lost — the committed versions are the correct ones. Recommendation: start test
   runs from a clean working tree (`git status` clean) so results reflect HEAD.

---

## Flutter unit tests (comprehensive)

The Flutter app (`flutter/`) had **no `test/` directory**. Added **494 tests
(1 skipped)** across **46 files** — run with `cd flutter && flutter test`. Tooling
note: only `flutter_test` is used; no `bloc_test`/`mocktail` were added (the dep tree
has many fragile `dependency_overrides`). A shared widget pump harness lives at
`test/support/widget_harness.dart` (`ScreenUtilInit` + `MaterialApp`).

Coverage by area:
- **Utils** — `validators` (email/phone/url/password + field validators), `formatters`
  (`relativeTime` with injected clock, dates, number/compact/currency).
- **Models / serialization** — `country_model`, `my_data_model`, `profile_room_model`,
  `public_user`, `profile_view_arguments`, `notification_models`, `search_user_model`:
  fromJson happy-path + missing/null keys + nested parsing + Hive map coercion +
  toJson round-trips + copyWith.
- **Network wrappers** — `ApiResponse`/`PaginatedResponse`/`Result`, `BaseResponse`.
- **Extensions / enums** — `extensions` (`parseValue<T>` every branch, RequestState),
  `enums`, `color_manager`, `user_data_extension`, `notification_data_extension`,
  localization engine (`app_translations` fallback chain + arg interpolation).
- **Media** — `image_type.resolve()` (svg/svga/raster/http/asset, all guards).
- **Config / gate** — `app_config`, `app_flow.resolveStart` (all branches), `app_theme`
  (`parseHexColor` + palette), `app_layout`, `nav_icons`, and the **launch-gate decision**
  (`LaunchGateResult.blocks`: force-update / maintenance / optional-update — mirrors the
  backend `/app-version` gate).
- **Registries** — `feature_registry` (enable/disable gating, routes, contributions,
  ordering, validateAll/initializeAll), `role`/`settings`/`widget`/`ui_contribution`,
  and the stac `field`/`stac_data`/`studio_slot` registries.
- **Widgets** (`test/shared/widgets/`, via the pump harness) — all 10 reusable widgets:
  `text`, `loading`, `button` (tap/`isLoading`/disabled), `text_button`, `text_input`
  (validator wiring, obscureText, onChanged, prefix/suffix), `image`/`network_image`,
  `app_bar`, `refresh_indicator`, `handling_data` (loading/loaded/empty/ban states).
- **ScreenUtil/style** — `DimensionsExt`/`PaddingExt`/`TextStyleExtensions` (pumped),
  `app_text_styles`, `system_ui_style`, `MediaUploadResult`.

Result: **494 tests (1 skipped — network-SVG decode), all passing.**

### Flutter bugs found & FIXED (2 — in `lib/features/notifications/notification_models.dart`)

6. **`NotificationItem.fromJson` — `id` was not null-safe** (`(json['id'] as num).toInt()`).
   A payload missing/`null` `id` threw `TypeError` instead of defaulting. **Fixed** →
   `(json['id'] as num?)?.toInt() ?? 0`.

7. **`NotificationItem.fromJson` — unsafe `data` cast** (`(json['data'] as Map?)?...`).
   A non-map `data` value (e.g. a String) threw and crashed the whole notification
   parse; the sibling `actor` field already used a safe `is Map` guard. **Fixed** →
   `json['data'] is Map ? (json['data'] as Map).cast<String,dynamic>() : const {}`.

(Both fixed in commit `b0d0615`; the two tests that documented them now assert the
corrected behavior.)

8. **Cross-stack note — envelope key `status` vs `success`.** The backend envelope uses
   `status` (see `Common::apiResponse`), but the Flutter `BaseResponse.fromJson` (and the
   unused `ApiResponse.fromJson`) read `success`. So `success` parses as `null` for a real
   backend payload (locked in by a test). Harmless **only** if call sites decide success
   from the HTTP status code rather than `BaseResponse.success`; worth a quick verify.

## Deep coverage — base internals + package internals + Flutter packages

Beyond the HTTP endpoints, a second pass covered the non-HTTP logic across the whole app.

### Backend base (PHP) — full suite now **825 tests**
- **Services** (`tests/Feature/Unit/`, ~105 tests) — UserDataService, MenuService,
  UserSettingService, PackageRegistry, ProfileContributorRegistry, notification/role/
  permission/email-template/translatable registries, StorageConfigService URL building,
  AuditLogger, NullWallet.
- **Models + Common helper + Support** (~141 tests) — User (casts/relations/`isOnline`/
  SoftDeletes/password mutator), Config (`map()` cache + invalidation), Page (`tr()`),
  Language (single-default), Notification (scopes), Profile (media accessors), Package,
  Country/StacScreen/Setting/Code/etc.; `Common::apiResponse` envelope + pagination meta;
  SocialPlatforms, Translatable, UtdManifest, AppLanguages, Auditable, DTOs.
- **Middleware + Requests + Mail + Events** (~55 tests) — GeneralBan, UserBan,
  CheckLatestToken, Localization, UpdateLastSeen, AuthRateLimiter, EnsurePackageEnabled,
  VerifyUtdSecret, StacAuth; Login/Register request rules + 422 envelope; EmailOtp
  (cooldown / daily-limit / TTL / brute-force lockout) + OtpCodeMail; the 4 events.

### Backend package internals (services/models/listeners — NOT endpoints)
- **moment / audio-room / profile** (~73 tests) — feed building + ordering, like/comment/
  react/report services, soft-delete & ownership, Room (owner/admin/password), blacklist
  expiry, charisma cache, profile infolist + media resolution.
- **gifts / reels / wallet** (~101 tests) — gift catalog/level/exp + GiftDirectory +
  `CreditRoomOwnerOnGiftSent` listener; reels like/view/comment services + counter clamps +
  video processing; wallet money precision, idempotent debit replay, held/available
  boundary, ChargeService, NullWallet exceptions.

### Flutter packages (pure-Dart, run from the main app context) — full suite now **978 tests**
Tested via `package:<name>/...` imports under `test/pkg/<name>/`:
- **gifts / wallet / profile** (117) — models, picker/wallet/profile cubit STATE classes,
  media resolution, profile computed getters (wealth/charm level, age, social stats).
- **moment / reels** (120) — models (+nested replies), entities, feed/comment/like state,
  `timeAgo`/`compactNumber` (en + ar pluralization), reaction/report key mappers.
- **authentication / utd_studio_sdk** (152) — auth models/params + bloc state, Stac
  coerce/binding/i18n, registries, parser models, screen store (fake cache+transport),
  generic action parsers.
- **audio-room** (95) — room/category/people models, all 5 bloc state classes + events,
  seat-icon choices, all 7 mode plugins (unique codes, grid math), charisma, translations.

### Bugs found & FIXED in this deep pass (2)

9. **`UserProfileModel.badges` — unsafe `as List?` cast** (Flutter profile package,
   `packages/profile/lib/src/domain/user_profile_model.dart`). A non-list `badges` value
   threw `TypeError` (the `?? []` only covered null). **Fixed** → `is List` guard, matching
   the sibling `covers`/`socialStats` coercers.

10. **`Common::paginationMeta` — crashed on cursor paginators** (`app/Helpers/Common.php`).
    `apiResponse()` accepts an `AbstractCursorPaginator` and the docblock advertised cursor
    support, but the meta builder unconditionally called `currentPage()` (absent on cursor
    paginators) → `BadMethodCallException`. **Fixed** → branch on type: `current_page` for
    page-number paginators, `next_cursor`/`prev_cursor` for cursor paginators.

### Bug documented (NOT fixed — load-bearing, needs a decision)

11. **`User::setPasswordAttribute` double-hash** (`app/Models/User.php`). It always
    `bcrypt()`s on assignment, so assigning an already-hashed value double-hashes it. Every
    current caller passes plaintext (registration / reset), so it's correct in practice, but
    a guard (or Laravel's `'password' => 'hashed'` cast) would prevent the footgun. Left as-is
    to avoid an app-wide behavior change; covered by a test asserting current behavior.

## Conclusion

The whole app is now under automated test: **825 backend tests** (endpoints + services +
models + middleware + every package's internals) and **978 Flutter tests** (base unit +
widgets + every package), all green. Four bugs surfaced — three **fixed** (notification
`id`/`data` casts, `UserProfileModel.badges` cast, `Common::paginationMeta` cursor crash)
and one **documented** (the `User` password double-hash, left for a product decision) —
plus the cross-stack `status` vs `success` envelope note (item 8) for your review.
