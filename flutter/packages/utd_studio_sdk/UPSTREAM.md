# UPSTREAM — vendored `stac` provenance & re-merge runbook

`utd_studio_sdk` is a **vendored fork** of the open-source [Stac](https://github.com/StacDev/stac)
Server-Driven UI framework. The upstream packages are copied **byte-for-byte**
under `vendor/` and consumed via `dependency_overrides`. We do **not** edit
anything under `vendor/`.

## Provenance

| Package | Vendored version | Path | Upstream license |
|---|---|---|---|
| `stac` | `1.5.0` | `vendor/stac` | MIT © 2024 Stac |
| `stac_core` | `1.5.0` | `vendor/stac_core` | MIT © 2024 Stac |
| `stac_framework` | `1.0.0` | `vendor/stac_framework` | MIT © 2025 Stac |
| `stac_logger` | `1.1.0` | `vendor/stac_logger` | MIT © 2025 Stac |

Source of the vendored copy: local pub cache
`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\<pkg>-<version>` (pinned versions above).
Only `example/` and `test/` were stripped; everything else (incl. the 169
committed `.g.dart` files in `stac_core`) is kept verbatim.

## ⚠️ dependency_overrides MUST live in every entrypoint

`pub` honours `dependency_overrides` **only from the entrypoint (app) pubspec**.
A sub/library package's overrides are ignored transitively. Therefore the
following block must be present **identically** in:

- `flutter/packages/utd_studio_sdk/pubspec.yaml` (for standalone analyze)
- `flutter/pubspec.yaml` (the `utd_app` Base — entrypoint)
- `chatPackageV2/flutter/pubspec.yaml` (entrypoint)

```yaml
dependency_overrides:
  stac:           { path: <…>/utd_studio_sdk/vendor/stac }
  stac_core:      { path: <…>/utd_studio_sdk/vendor/stac_core }
  stac_framework: { path: <…>/utd_studio_sdk/vendor/stac_framework }
  stac_logger:    { path: <…>/utd_studio_sdk/vendor/stac_logger }
```

If you forget one, `pub` fetches the **real** `stac` from pub.dev → you get
**two copies** of the engine, `StacParser` type identity breaks, and parser /
action registration silently no-ops. A CI grep guards against `package:stac/`
imports outside `vendor/`.

## Re-merge runbook (bumping upstream)

1. Fetch the target upstream version (pub cache or a GitHub tag of `StacDev/stac`).
2. For each of the 4 packages: **replace `vendor/<pkg>/lib` wholesale** (and
   `pubspec.yaml`/`CHANGELOG.md` if changed). Copy the **entire** `lib/`,
   including all generated `.g.dart` — never run `build_runner` against
   `vendor/`, and never copy selectively.
3. Update the provenance table above with the new versions.
4. Update the override blocks if a package name/coordinate changed.
5. `flutter pub get` + `flutter analyze` in `utd_studio_sdk`, then in `utd_app`
   and `chatPackageV2`; run the verification checklist in
   `docs/UTD-STUDIO-SDK-EXTRACTION-PLAN.md`.

## Rebrand note

We deliberately **do not** rename the internal `Stac*` symbols (`Stac`,
`StacParser`, `StacActionParser`, `StacFormScope`, …). Branding is applied at
the package level (`utd_studio_sdk` / "UTD Studio") and through the `UtdStudio`
facade. Stack traces showing `Stac…` frames are expected, not bugs. A deep
rename would force editing ~696 vendored files (incl. 169 `.g.dart`) on every
re-merge — explicitly avoided.
