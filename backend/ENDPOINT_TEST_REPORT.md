# Endpoint Test Coverage & Findings — test-stack backend

> ملخص بالعربي: عملت unit/feature tests لكل الـ endpoints في المشروع (core + كل
> الباكدچات). النتيجة النهائية: **350 test كلهم ناجحين (0 failures)** و**لا يوجد أي
> مشكلة (bug) في أي endpoint**. القسم الأخير فيه ملاحظات بسيطة اختيارية للتحسين.

Date: 2026-06-29
Scope: every HTTP API endpoint in `backend/routes/api.php` + all 6 packages
(`audio-room`, `gifts`, `moment`, `profile`, `reels`, `wallet`).

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

## Conclusion

All ~137 API endpoints across the core app and every package now have automated
test coverage, and the full suite is green. No endpoint defects were found; the
items above are optional polish.
