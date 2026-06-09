# UTD — Screen Contract & App Flow (Integration Spec)

How a UTD-Studio-designed app tells this Flutter runtime **what each screen is**
and **how navigation flows**, without hardcoding screen names anywhere.

> A screen's *display name* is cosmetic — the customer renames it freely. The
> runtime acts only on the **contract** (role + entry policy) and a single
> global **flow map**.

---

## 1. The two data structures

### a) `AppFlow` — global named slots (one per app / variant)

Each slot is just a **route path**, so any screen can fill any slot.

| Slot | Meaning | Behaviour |
|------|---------|-----------|
| `splash` | shown every launch while the start route resolves | always |
| `firstRun` | landing / intro | shown **once per lifetime** |
| `unauthenticated` | where to send a logged-out user | also the destination on token expiry |
| `home` | authenticated landing | — |
| `onAuthSuccess` | after a successful login | defaults to `home` |
| `onLogout` | after logout | defaults to `unauthenticated` |

```json
"flow": {
  "splash": "/splash",
  "firstRun": "/intro",
  "unauthenticated": "/login",
  "home": "/",
  "onAuthSuccess": "/",
  "onLogout": "/login"
}
```

### b) `ScreenContract` — per-screen self-description

```json
"contract": { "role": "auth.login", "requiresAuth": false, "showOnce": false }
```

| Field | Type | Effect |
|-------|------|--------|
| `role` | string? | semantic role (see vocabulary below) or `custom:<name>` or null |
| `requiresAuth` | bool | entering without a session → redirect to `flow.unauthenticated` |
| `showOnce` | bool | shown at most once per lifetime; once seen the guard routes away |

### Role vocabulary (curated + open)

`auth.login` · `auth.register` · `auth.forgot` · `auth.profile` ·
`onboarding.intro` · `app.home` · `app.settings` · `app.splash` ·
`custom:<anything>`

The runtime only special-cases what it knows; unknown/`custom:` roles are inert
labels (useful for Studio UX and your own `switch`).

---

## 2. Hybrid ownership

- **The base (this repo)** declares the slots and their behaviour, and ships a
  `fallback` flow mirroring its own core screens — see
  [`lib/config/app_flow.dart`](../lib/config/app_flow.dart).
- **The customer (in Studio)** picks *which screen* fills each slot. That config
  is delivered via the manifest and applied at startup with
  `AppFlow.override(parsedFlow)` — until then `AppFlow.fallback` is used.

---

## 3. The entire Flutter surface (fixed — 4 touch-points)

1. **Boot decision** — `AppFlow.resolveStart`:
   ```dart
   if (hasSession)           return home;        // returning, logged in
   if (!seen(firstRun))      return firstRun;    // true first run
   return unauthenticated;                       // returning, logged out
   ```
   The splash marks `firstRun` seen the moment it routes there
   (`packages/authentication/.../auth_impl.dart`).

2. **Route guard** — GoRouter `redirect` reads the contract
   ([`lib/config/router.dart`](../lib/config/router.dart)):
   ```dart
   if (contract.requiresAuth && !hasSession) return flow.unauthenticated;
   if (contract.showOnce && seen(location))  return hasSession ? flow.home
                                                               : flow.unauthenticated;
   ```

3. **401 / expired** — the API client clears the session
   (`CacheManager.clear`, which **preserves** `seen:` flags). The next
   navigation is then redirected to `flow.unauthenticated` by the guard.
   *(Optional: trigger an immediate redirect via a global navigator key.)*

4. **Actions** resolve named outcomes from the flow, not literals:
   ```dart
   context.go(AppFlow.instance.onAuthSuccess);  // core.login
   context.go(AppFlow.instance.onLogout);       // core.logout
   ```

---

## 4. "Show once" semantics

- Backed by `CacheManager.seen(key)` / `markSeen(key)`, keyed by the screen's
  **stable route** — never its display name, so renaming never re-triggers it.
- Scope is **lifetime**: shown once, never again (logout preserves the flag).

---

## 5. The two scenarios this implements

| Scenario | Result |
|----------|--------|
| First install | splash → **intro (once)** → login → home |
| Reopen, not logged in | splash → **login** (intro skipped) |
| Reopen, logged in | splash → **home** |
| Logout | → **login** (not intro) |
| Token expired | session cleared → **login** |

---

## 6. Checklist for a new app / variant

1. Define your `AppFlow` slots (or rely on `fallback`).
2. Tag each screen's `contract` (role + `requiresAuth`/`showOnce`).
3. Ensure `unauthenticated` points at a screen with **no** `requiresAuth`
   (else: redirect loop — Studio warns about this).
4. That's it — boot, guard, expiry and action navigation are already wired.
