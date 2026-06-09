import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

import '../stac_binding.dart';
import '../stac_data_registry.dart';

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

    // Re-fetch when the source's data is invalidated (e.g. avatar changed). The
    // ValueKey forces FutureBuilder to re-run its future on each revision bump.
    return ValueListenableBuilder<int>(
      valueListenable: StacDataRegistry.instance.revision,
      builder: (context, revision, _) {
        return FutureBuilder<Map<String, dynamic>>(
          key: ValueKey('$source#$revision'),
          future: StacDataRegistry.instance.fetchObject(source),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final item = snapshot.data ?? const <String, dynamic>{};
            final resolved = StacBinding.resolve(child, item);
            return Stac.fromJson(resolved, context) ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
