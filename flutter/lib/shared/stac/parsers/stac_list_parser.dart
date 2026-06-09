import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

import '../stac_binding.dart';
import '../stac_data_registry.dart';

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

    debugPrint('[UTD] utdList parse: source=$source registered=${StacDataRegistry.instance.hasList(source)}');

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: StacDataRegistry.instance.fetchList(source),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final items = snapshot.data ?? const [];
        debugPrint('[UTD] utdList "$source" -> ${items.length} items');
        if (items.isEmpty) {
          // تشخيص مؤقت: يبيّن إن الـ parser اشتغل لكن المصدر رجّع 0
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'لا توجد بيانات (source: $source, registered: ${StacDataRegistry.instance.hasList(source)})',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        final list = ListView.builder(
          shrinkWrap: model.shrinkWrap,
          reverse: model.reverse,
          physics: model.shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : null,
          padding: model.padding != null
              ? EdgeInsets.all(model.padding!)
              : EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final resolved = StacBinding.resolve(template, items[index]);
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
      },
    );
  }
}
