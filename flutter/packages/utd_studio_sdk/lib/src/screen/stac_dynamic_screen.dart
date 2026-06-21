import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

import '../core/stac_coerce.dart';
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
    // Parse-once: after the tree is built we always return the same instance.
    if (_tree != null) return _tree!;

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
    // force-parse: fix wrong primitive types (text.data/src…) before Stac throws.
    final rendered = Stac.fromJson(StacCoerce.sanitize(json), context);
    return rendered ??
        (widget.fallback ??
            StudioRuntime.instance.fallbackBuilder?.call(context) ??
            _missing(context));
  }

  Widget _missing(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا توجد شاشة منشورة باسم "${widget.screenName}" بعد.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
