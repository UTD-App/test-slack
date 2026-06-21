# UTD Studio SDK (`utd_studio_sdk`)

**UTD Studio** is the Flutter **Server-Driven UI (SDUI)** runtime: it renders
screens authored in the UTD Studio editor from JSON delivered by your backend —
no app-store release needed to change a screen.

It is a **vendored fork** of the open-source [`stac`](https://github.com/StacDev/stac)
framework (bundled under `vendor/`) plus the UTD layer on top:

- the shared **data-binding registry** (`StacDataRegistry`) and template binder (`StacBinding`)
- the **UTD widget parsers** (`utdList`, `utdObject`, `utdTabs`, `utdTextField`, `utdScroll`, `utdSized`, …)
- the **generic actions** (`core.navigate`, `core.back`, `core.openDialog`, `core.closeDialog`, `core.toggleTheme`, `core.setLocale`)
- the **screen store** (cache-first fetch + version sync)
- a single **`UtdStudio.init()`** entry point that wires everything via injectable ports.

> One package: a developer adds `utd_studio_sdk` and imports
> `package:utd_studio_sdk/utd_studio_sdk.dart` — never `package:stac/...`.

## Quick start

```dart
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

await UtdStudio.init(StudioConfig(
  transport: MyHttpTransport(),   // StacTransport over your HTTP client (/stac, ...)
  cache:     MyKeyValueCache(),   // KeyValueCache over Hive / SharedPreferences / memory
  navigator: MyNavigator(),       // optional — for core.navigate / core.back / core.openDialog
  theme:     MyThemeSource(),     // optional — core.toggleTheme
  locale:    MyLocaleSource(),    // optional — core.setLocale
  toast:     MyToastSink(),       // optional
  extraParsers: [/* your custom StacParser widgets */],
  extraActions: [/* your custom StacActionParser actions */],
));

// Render a server-driven screen by name:
StacDynamicScreen(screenName: 'profile');

// Register a data source your screens bind to:
UtdStudio.registerObject('core.currentUser', () async => myUserMap);
```

Your backend must serve the screen contract: `GET /stac`, `GET /stac/{name}`,
`GET /stac/{name}/version`.

## Notes

- **Internal symbols keep the `Stac*` names** (the fork is unmodified). Branding
  is at the package + `UtdStudio` facade level. See `UPSTREAM.md`.
- **Vendoring & re-merge**: see `UPSTREAM.md` (incl. the critical
  `dependency_overrides` requirement in every entrypoint pubspec).
- **Licenses**: original UTD code under `lib/` — see `LICENSE`; vendored MIT
  components under `vendor/` — see `NOTICE`.
