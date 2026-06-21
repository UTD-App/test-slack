import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

import '../core/stac_binding.dart';
import '../core/stac_data_registry.dart';

/// Model for a data-bound single-object node:
/// ```json
/// {
///   "type": "utdObject",
///   "source": "core.currentUser",
///   "child": { ...stac subtree with `binding` fields... }
/// }
/// ```
class StacUtdObject {
  const StacUtdObject({required this.source, required this.child});

  final String? source;
  final Map<String, dynamic>? child;

  factory StacUtdObject.fromJson(Map<String, dynamic> json) {
    return StacUtdObject(
      source: json['source'] as String?,
      child: (json['child'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// Renders a `utdObject`: pulls a single record for `source` from
/// [StacDataRegistry] and renders `child` once with its bindings resolved.
///
/// Used for screens that bind to one entity (e.g. the profile screen → the
/// current user), the scalar counterpart of `utdList`.
class StacUtdObjectParser extends StacParser<StacUtdObject> {
  const StacUtdObjectParser();

  @override
  String get type => 'utdObject';

  @override
  StacUtdObject getModel(Map<String, dynamic> json) =>
      StacUtdObject.fromJson(json);

  @override
  Widget parse(BuildContext context, StacUtdObject model) {
    final source = model.source;
    final child = model.child;

    if (source == null || child == null) {
      return const SizedBox.shrink();
    }
    return _UtdObjectView(source: source, template: child);
  }
}

/// Stateful view for a `utdObject`. Listens to [StacDataRegistry.revision] and
/// re-fetches on each bump, but **keeps the last resolved tree on screen while
/// re-fetching** (e.g. after an avatar change) instead of flashing a spinner
/// that covers the whole region. The spinner shows only on the very first load
/// (no data yet). Flutter then diffs the rebuilt tree, so only the part whose
/// bound value actually changed (e.g. the avatar `Image`) repaints.
class _UtdObjectView extends StatefulWidget {
  const _UtdObjectView({required this.source, required this.template});

  final String source;
  final Map<String, dynamic> template;

  @override
  State<_UtdObjectView> createState() => _UtdObjectViewState();
}

class _UtdObjectViewState extends State<_UtdObjectView> {
  /// Last fetched record. While non-null we render from it during any re-fetch.
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    StacDataRegistry.instance.revision.addListener(_onRevision);
    _fetch();
  }

  void _onRevision() => _fetch();

  Future<void> _fetch() async {
    final rev = StacDataRegistry.instance.revision.value;
    final result = await StacDataRegistry.instance.fetchObject(widget.source);
    if (!mounted) return;
    // A newer revision arrived while fetching → drop this stale result.
    if (rev != StacDataRegistry.instance.revision.value) return;
    setState(() => _data = result);
  }

  @override
  void dispose() {
    StacDataRegistry.instance.revision.removeListener(_onRevision);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      // First load only — no data cached yet.
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final resolved = StacBinding.resolve(widget.template, data);
    return Stac.fromJson(resolved, context) ?? const SizedBox.shrink();
  }
}
