import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

import '../core/stac_binding.dart';
import '../core/stac_data_registry.dart';

/// Model for a data-bound list node:
/// ```json
/// {
///   "type": "utdList",
///   "source": "chat.conversations",
///   "shrinkWrap": false,
///   "reverse": false,
///   "itemTemplate": { ...stac subtree with `binding` fields... }
/// }
/// ```
class StacUtdList {
  const StacUtdList({
    required this.source,
    required this.itemTemplate,
    this.shrinkWrap = false,
    this.reverse = false,
    this.padding,
    this.onItemTap,
  });

  final String? source;
  final Map<String, dynamic>? itemTemplate;
  final bool shrinkWrap;
  final bool reverse;
  final double? padding;

  /// Optional action fired when a row is tapped. The base merges the tapped
  /// row's raw data into the action under `item` before dispatch, so any
  /// action (navigate / package action / dialog) can read the row's id.
  final Map<String, dynamic>? onItemTap;

  factory StacUtdList.fromJson(Map<String, dynamic> json) {
    return StacUtdList(
      source: json['source'] as String?,
      itemTemplate: (json['itemTemplate'] as Map?)?.cast<String, dynamic>(),
      shrinkWrap: json['shrinkWrap'] as bool? ?? false,
      reverse: json['reverse'] as bool? ?? false,
      padding: (json['padding'] as num?)?.toDouble(),
      onItemTap: (json['onItemTap'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// Renders a `utdList`: pulls the data for `source` from [StacDataRegistry],
/// then renders `itemTemplate` once per item with its bindings resolved.
class StacUtdListParser extends StacParser<StacUtdList> {
  const StacUtdListParser();

  @override
  String get type => 'utdList';

  @override
  StacUtdList getModel(Map<String, dynamic> json) => StacUtdList.fromJson(json);

  @override
  Widget parse(BuildContext context, StacUtdList model) {
    final source = model.source;
    final template = model.itemTemplate;

    if (source == null || template == null) {
      return const SizedBox.shrink();
    }
    return _UtdListView(model: model, source: source, template: template);
  }
}

/// Stateful view for a `utdList`. Mirrors `utdObject`: listens to
/// [StacDataRegistry.revision], re-fetches on each bump, and **keeps the last
/// list on screen while re-fetching** instead of flashing a spinner. The
/// spinner shows only on the first load (no data yet). Combined with the
/// parse-once screen, the `ListView`'s scroll position survives navigation.
class _UtdListView extends StatefulWidget {
  const _UtdListView({
    required this.model,
    required this.source,
    required this.template,
  });

  final StacUtdList model;
  final String source;
  final Map<String, dynamic> template;

  @override
  State<_UtdListView> createState() => _UtdListViewState();
}

class _UtdListViewState extends State<_UtdListView> {
  /// Last fetched rows. While non-null we render from them during any re-fetch.
  List<Map<String, dynamic>>? _items;

  @override
  void initState() {
    super.initState();
    StacDataRegistry.instance.revision.addListener(_onRevision);
    _fetch();
  }

  void _onRevision() => _fetch();

  Future<void> _fetch() async {
    final rev = StacDataRegistry.instance.revision.value;
    final result = await StacDataRegistry.instance.fetchList(widget.source);
    if (!mounted) return;
    // A newer revision arrived while fetching → drop this stale result.
    if (rev != StacDataRegistry.instance.revision.value) return;
    setState(() => _items = result);
  }

  @override
  void dispose() {
    StacDataRegistry.instance.revision.removeListener(_onRevision);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final items = _items;

    // First load only — no rows fetched yet.
    if (items == null) {
      const loader = Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
      return model.shrinkWrap ? loader : const Expanded(child: loader);
    }

    if (items.isEmpty) {
      return model.shrinkWrap
          ? const SizedBox.shrink()
          : const Expanded(child: SizedBox.shrink());
    }

    final list = ListView.builder(
      shrinkWrap: model.shrinkWrap,
      reverse: model.reverse,
      physics:
          model.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: model.padding != null
          ? EdgeInsets.all(model.padding!)
          : EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final resolved = StacBinding.resolve(widget.template, items[index]);
        // Give every interactive element *inside* the row (inner like /
        // comment buttons, per-row menus…) the same row context the
        // row-level tap gets, so their actions can read `model['item']`.
        StacBinding.injectItemContext(resolved, items[index]);
        // Row tap → dispatch the action with the raw row merged in as
        // `item`, so the (package-owned) action can read the row's id.
        final tap = model.onItemTap;
        if (tap != null) {
          final wrapped = <String, dynamic>{
            'type': 'gestureDetector',
            'onTap': {...tap, 'item': items[index]},
            'child': resolved,
          };
          return Stac.fromJson(wrapped, context) ?? const SizedBox.shrink();
        }
        return Stac.fromJson(resolved, context) ?? const SizedBox.shrink();
      },
    );

    // When inside an unbounded parent (e.g. a Column), give the list a
    // flexible slot instead of forcing the caller to wrap it.
    return model.shrinkWrap ? list : Expanded(child: list);
  }
}
