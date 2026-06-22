import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

import '../core/stac_coerce.dart';
import '../runtime/studio_runtime.dart';
import 'stac_map_action.dart';

/// The app-agnostic core actions bundled with UTD Studio. They drive
/// navigation, theming, locale and dialogs through the ports resolved at
/// `UtdStudio.init` ([StudioRuntime]) — never through app code directly.
///
/// App-specific actions (auth/profile/avatar/logout) live in the host app and
/// are passed via `StudioConfig.extraActions`.

/// `core.navigate` — `{ actionType, route, mode: go|push|replace, extra? }`
class CoreNavigateActionParser extends StacMapActionParser {
  const CoreNavigateActionParser();

  @override
  String get actionType => 'core.navigate';

  @override
  void onCall(BuildContext context, Map<String, dynamic> model) {
    final route = (model['route'] as String?)?.trim();
    if (route == null || route.isEmpty) return;
    final nav = StudioRuntime.instance.navigator;
    if (nav == null) return;
    // Default push: navigating to a sub-screen keeps the back button working.
    final mode = (model['mode'] as String?) ?? 'push';
    final extra = model['extra'];
    switch (mode) {
      case 'push':
        nav.push(context, route, extra: extra);
      case 'replace':
        nav.replace(context, route, extra: extra);
      default:
        nav.go(context, route, extra: extra);
    }
  }
}

/// `core.back` — pops to the previous screen, or to `fallback`/home when there
/// is nothing to pop (there is no automatic AppBar back button).
class CoreBackActionParser extends StacMapActionParser {
  const CoreBackActionParser();

  @override
  String get actionType => 'core.back';

  @override
  void onCall(BuildContext context, Map<String, dynamic> model) {
    final nav = StudioRuntime.instance.navigator;
    if (nav == null) return;
    if (nav.canPop(context)) {
      nav.pop(context);
      return;
    }
    final route = (model['fallback'] as String?)?.trim();
    nav.go(context, (route != null && route.isNotEmpty) ? route : nav.home);
  }
}

/// `core.toggleTheme` — `{ actionType, mode? }` (mode: light|dark|system).
class CoreToggleThemeActionParser extends StacMapActionParser {
  const CoreToggleThemeActionParser();

  @override
  String get actionType => 'core.toggleTheme';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final theme = StudioRuntime.instance.theme;
    if (theme == null) return;
    final mode = model['mode'] as String?;
    if (mode == 'light' || mode == 'dark' || mode == 'system') {
      await theme.setMode(mode);
    } else {
      await theme.toggle();
    }
  }
}

/// `core.setLocale` — `{ actionType, code }`.
class CoreSetLocaleActionParser extends StacMapActionParser {
  const CoreSetLocaleActionParser();

  @override
  String get actionType => 'core.setLocale';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final code = (model['code'] as String?)?.trim();
    if (code == null || code.isEmpty) return;
    final locale = StudioRuntime.instance.locale;
    if (locale == null) return;
    await locale.setLanguage(code); // adapter swallows unsupported codes
  }
}

/// `core.openDialog` — opens a UTD-Studio screen (type `dialog`) **above** the
/// current screen instead of navigating to it. `{ actionType, screen, style?,
/// height?, expandable?, barrierDismissible? }`.
///
/// Presentation defaults live on the dialog screen JSON under `presentation`;
/// the action may override per-call. Styles: `center` | `sheet` | `full`.
class CoreOpenDialogActionParser extends StacMapActionParser {
  const CoreOpenDialogActionParser();

  @override
  String get actionType => 'core.openDialog';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final raw =
        (model['screen'] as String? ?? model['route'] as String?)?.trim();
    if (raw == null || raw.isEmpty) return;
    // The Studio stores a screen **route** (e.g. "/s/shash_18"), but the screen
    // store keys by **name** (shash_18). Accept both and strip the route prefix.
    final name = raw.startsWith('/s/')
        ? raw.substring(3)
        : (raw.startsWith('/') ? raw.substring(1) : raw);
    if (name.isEmpty) return;

    // Read THE SAME screen source resolved at init (synced cache), never a fresh
    // store — otherwise the dialog would render empty.
    final screen = await StudioRuntime.instance.screenSource.getScreen(name);
    if (screen == null || !context.mounted) return;

    final base = (screen['presentation'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final style =
        (model['style'] as String? ?? base['style'] as String?)?.trim() ??
            'center';
    final height =
        (model['height'] as num? ?? base['height'] as num?)?.toDouble() ?? 75;
    final expandable =
        model['expandable'] as bool? ?? base['expandable'] as bool? ?? true;
    final dismissible = model['barrierDismissible'] as bool? ??
        base['barrierDismissible'] as bool? ??
        true;

    switch (style) {
      case 'sheet':
        await _showSheet(context, screen, height, expandable, dismissible);
      case 'full':
        await _showFull(context, screen, dismissible);
      default:
        await _showCenter(context, screen, dismissible);
    }
  }

  /// Builds the dialog body from the screen JSON (minus `presentation`).
  Widget _content(BuildContext context, Map<String, dynamic> screen) {
    final json = Map<String, dynamic>.from(screen)..remove('presentation');
    return Stac.fromJson(StacCoerce.sanitize(json), context) ??
        const SizedBox.shrink();
  }

  Future<void> _showCenter(
      BuildContext context, Map<String, dynamic> screen, bool dismissible) {
    return showDialog<void>(
      context: context,
      barrierDismissible: dismissible,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(22),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.78,
          ),
          child: SingleChildScrollView(child: _content(ctx, screen)),
        ),
      ),
    );
  }

  Future<void> _showSheet(BuildContext context, Map<String, dynamic> screen,
      double height, bool expandable, bool dismissible) {
    final initial = (height.clamp(20, 100)) / 100.0;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: initial,
        minChildSize: (initial * 0.6).clamp(0.2, initial),
        maxChildSize: expandable ? 1.0 : initial,
        expand: false,
        builder: (ctx, scrollController) => Material(
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SingleChildScrollView(
            controller: scrollController,
            child: _content(ctx, screen),
          ),
        ),
      ),
    );
  }

  Future<void> _showFull(
      BuildContext context, Map<String, dynamic> screen, bool dismissible) {
    // A `full` Studio screen is itself a complete scaffold (the Studio transform
    // wraps every screen in scaffold → scrollView). Rendering that scaffold
    // inside `Dialog.fullscreen` DOUBLE-WRAPS it and breaks badly: the dialog's
    // own Material surface paints OVER the screen's background (white), the
    // inner max-size column overflows the dialog's bounded box (RenderFlex
    // overflow), and on any rebuild the app shell bleeds through the overlay.
    // Pushing it as a normal full-screen ROUTE renders it exactly like a
    // bottom-nav tab (which works), dismissible with the system back gesture.
    // Wrapped in [_FullStudioPage] so the screen's content stays clear of the
    // status bar / camera cutout (SafeArea), the strip behind the status bar is
    // painted (nothing shows through), and a back button is overlaid (the screen
    // has no app bar of its own).
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => _FullStudioPage(child: _content(ctx, screen)),
      ),
    );
  }
}

/// Chrome for a `style:'full'` Studio screen pushed as a route. The screen is a
/// bare scaffold with no app bar, so without this its first widget jams under
/// the status bar / camera cutout. This: (a) insets the content below the status
/// bar (SafeArea), (b) paints the status-bar strip with the theme background so
/// nothing behind shows through, (c) overlays a circular back button at the
/// top-start (physical top-right in RTL) — opposite the screen's own cover tools
/// (edit/refresh, which sit at top-end).
class _FullStudioPage extends StatelessWidget {
  const _FullStudioPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: child),
            // Physical top-RIGHT, opposite the screen's own cover tools
            // (edit/refresh render at the start/left edge).
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: const Color(0x66000000),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  iconSize: 22,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `core.closeDialog` — dismisses the dialog/sheet opened by `core.openDialog`,
/// using the local navigator so it pops the overlay, never the screen beneath.
class CoreCloseDialogActionParser extends StacMapActionParser {
  const CoreCloseDialogActionParser();

  @override
  String get actionType => 'core.closeDialog';

  @override
  void onCall(BuildContext context, Map<String, dynamic> model) {
    Navigator.of(context).maybePop();
  }
}

/// The app-agnostic actions registered by `UtdStudio.init`.
const List<StacActionParser> genericStacActionParsers = [
  CoreNavigateActionParser(),
  CoreBackActionParser(),
  CoreOpenDialogActionParser(),
  CoreCloseDialogActionParser(),
  CoreToggleThemeActionParser(),
  CoreSetLocaleActionParser(),
];
