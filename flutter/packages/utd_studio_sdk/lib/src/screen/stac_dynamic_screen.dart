import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

import '../core/stac_coerce.dart';
import '../core/stac_i18n.dart';
import '../core/studio_slot_registry.dart';
import '../interfaces/interfaces.dart';
import '../runtime/studio_runtime.dart';

/// Renders a server-driven screen authored in UTD Studio.
///
/// Flow: read the screen JSON from the runtime's screen source (cache-first for
/// an instant first frame, then a background refresh), and render it with the
/// Stac engine. Custom widgets like `utdList` resolve their own data via
/// `StacDataRegistry`.
///
/// When no JSON is available yet (never published, or offline on first run),
/// the per-instance [fallback], then `StudioConfig.fallbackBuilder`, then a
/// built-in placeholder is shown.
class StacDynamicScreen extends StatefulWidget {
  const StacDynamicScreen({
    super.key,
    required this.screenName,
    this.fallback,
  });

  final String screenName;
  final Widget? fallback;

  @override
  State<StacDynamicScreen> createState() => _StacDynamicScreenState();
}

class _StacDynamicScreenState extends State<StacDynamicScreen> {
  /// Synchronously-available cached screen JSON (if synced on a previous run).
  /// When present we render it immediately on the first build (no spinner flash).
  Map<String, dynamic>? _cached;

  /// True while the first (uncached) fetch is in flight — shows a spinner once.
  bool _loading = false;

  /// The rendered tree, built **once** and returned as-is on every later build.
  /// This stops `Stac.fromJson` from re-parsing the whole screen on each parent
  /// rebuild: the same widget instance is returned, Flutter skips diffing, and
  /// the subtree — scroll offset, field focus, `utdObject`/`utdList` state —
  /// stays alive. Data-bound regions still refresh via `StacDataRegistry`.
  Widget? _tree;

  /// Language the cached [_tree] was localised for. When the app locale changes
  /// we drop [_tree] and re-render so translated labels follow the new language.
  String? _treeLocale;

  StacScreenSource get _source => StudioRuntime.instance.screenSource;

  @override
  void initState() {
    super.initState();
    _cached = _source.getScreenCached(widget.screenName);
    if (_cached == null) {
      // Nothing cached: fetch (one-time spinner) and rebuild when it lands.
      _loading = true;
      _source.getScreen(widget.screenName).then((json) {
        if (!mounted) return;
        setState(() {
          _cached = json;
          _loading = false;
        });
      });
    } else {
      // Have a cached copy: refresh in the background for next time, but do NOT
      // swap the live tree (a version bump applies on the next visit/mount).
      _source.getScreen(widget.screenName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-localise when the app language changes (drop the cached tree).
    final locale = Localizations.maybeLocaleOf(context)?.languageCode;
    if (_tree != null && _treeLocale != locale) _tree = null;

    // Parse-once: after the tree is built we always return the same instance.
    if (_tree != null) return _tree!;
    _treeLocale = locale;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final json = _cached;
    if (json == null) {
      return widget.fallback ??
          StudioRuntime.instance.fallbackBuilder?.call(context) ??
          _missing(context);
    }
    return _tree = _render(context, json);
  }

  Widget _render(BuildContext context, Map<String, dynamic> json) {
    // Inject any package slot contributions for this screen (e.g. the wallet's
    // coin card on `profile`) BEFORE localise/parse, so injected nodes flow
    // through the same i18n + binding pipeline. No-op when nothing is registered.
    final withSlots =
        StudioSlotRegistry.instance.injectScreenSlots(widget.screenName, json);
    // Localise translatable Text (tKey / t.* binding) → current-locale strings,
    // then force-parse to fix wrong primitive types before Stac throws.
    final localized = localizeStac(withSlots, context);
    final rendered = Stac.fromJson(StacCoerce.sanitize(localized), context);
    return rendered ??
        (widget.fallback ??
            StudioRuntime.instance.fallbackBuilder?.call(context) ??
            _missing(context));
  }

  /// Translation key for the "no published screen yet" placeholder. Routed
  /// through the runtime translate port when wired; otherwise a neutral English
  /// default is shown. The SDK never imports app code — it only asks the port.
  static const _missingKey = 'studio.no_published_screen';

  Widget _missing(BuildContext context) {
    final translate = StudioRuntime.instance.translate;
    // Neutral English default (used when no port is wired, or the key is missing
    // from the catalog — the port returns the key unchanged on a miss).
    var text = 'No published screen named "${widget.screenName}" yet.';
    if (translate != null) {
      final value = translate(context, _missingKey);
      if (value.isNotEmpty && value != _missingKey) {
        // Interpolate the screen name into the localized template if it has a
        // placeholder; otherwise use the localized string as-is.
        text = value.contains('{name}')
            ? value.replaceAll('{name}', widget.screenName)
            : value;
      }
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
