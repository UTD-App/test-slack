import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;
import 'package:utd_app/shared/services/stac_service.dart';
import 'package:utd_app/shared/stac/stac_coerce.dart';

/// Renders a server-driven screen pushed from UTD Studio.
///
/// Flow: fetch the screen JSON from the app's [StacService] (which syncs it
/// from the Base Project backend and caches it in Hive), then render it with
/// the Stac engine. Custom widgets like `utdList` resolve their own data via
/// [StacDataRegistry].
///
/// If no JSON is available yet (never pushed, or offline on first run), the
/// optional [fallback] is shown so a package can degrade to a built-in screen.
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
  /// Synchronously-available cached screen JSON (if this screen was synced on a
  /// previous run / app startup). When present we render it immediately on the
  /// first build instead of going through a `FutureBuilder` spinner→content
  /// swap.
  Map<String, dynamic>? _cached;

  /// Used only when there is no cached copy yet — fetch then show.
  Future<Map<String, dynamic>?>? _future;

  @override
  void initState() {
    super.initState();
    _cached = StacService.instance.getScreenCached(widget.screenName);
    if (_cached == null) {
      // Nothing cached: fetch (with a spinner) and rebuild when it arrives.
      _future = StacService.instance.getScreen(widget.screenName);
    } else {
      // Have a cached copy: refresh in the background for next time, but do NOT
      // swap the live tree (the swap is what blanked pushed screens on some
      // devices). A version bump simply applies on the next visit.
      StacService.instance.getScreen(widget.screenName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fast path: render the cached screen directly (no FutureBuilder swap).
    //
    // Rendering server-driven screens through a `FutureBuilder` that swaps a
    // loading `Scaffold` for the real one was observed to leave a *pushed*
    // screen's body subtree attached but never laid out on device (Impeller) —
    // a blank/white screen with no exception. Rendering synchronously from
    // cache builds the real tree on the first frame, exactly like the path that
    // always lays out correctly.
    if (_cached != null) {
      return _render(context, _cached!);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final json = snapshot.data;
        if (json == null) {
          return widget.fallback ?? _missing(context);
        }
        return _render(context, json);
      },
    );
  }

  Widget _render(BuildContext context, Map<String, dynamic> json) {
    // force-parse: نصحّح الأنواع الغلط (text.data/src… ) قبل ما Stac يكسر
    final rendered = Stac.fromJson(StacCoerce.sanitize(json), context);
    return rendered ?? (widget.fallback ?? _missing(context));
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
