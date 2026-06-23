import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

/// Model for an RTL-aware positioned node inside a Stack:
/// ```json
/// {
///   "type": "utdPositionedDirectional",
///   "start": 0,   // optional — distance from the leading edge (right in RTL)
///   "top": 0,     // optional
///   "end": 0,     // optional — distance from the trailing edge (left in RTL)
///   "bottom": 0,  // optional
///   "width": 100, // optional
///   "height": 40, // optional
///   "child": { ...stac subtree... }
/// }
/// ```
class StacUtdPositionedDirectional {
  const StacUtdPositionedDirectional({
    this.start,
    this.top,
    this.end,
    this.bottom,
    this.width,
    this.height,
    this.child,
  });

  final double? start;
  final double? top;
  final double? end;
  final double? bottom;
  final double? width;
  final double? height;
  final Map<String, dynamic>? child;

  factory StacUtdPositionedDirectional.fromJson(Map<String, dynamic> json) {
    return StacUtdPositionedDirectional(
      start: (json['start'] as num?)?.toDouble(),
      top: (json['top'] as num?)?.toDouble(),
      end: (json['end'] as num?)?.toDouble(),
      bottom: (json['bottom'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      child: (json['child'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// Renders a `utdPositionedDirectional`: the RTL-aware counterpart of Stac's
/// built-in `positioned` (which uses absolute left/right). `start`/`end` resolve
/// against the ambient [Directionality], so a Studio screen authored once lays
/// out correctly in both LTR and RTL.
///
/// The UTD Studio editor emits this type for directional `Positioned` nodes;
/// without a registered parser the whole screen blows up with
/// "Widget type not found — utdPositionedDirectional" (e.g. the profile/Me tab).
///
/// MUST be a direct child of a `Stack` (Flutter asserts otherwise). When `child`
/// is absent it renders an empty box rather than throwing.
class StacUtdPositionedDirectionalParser
    extends StacParser<StacUtdPositionedDirectional> {
  const StacUtdPositionedDirectionalParser();

  @override
  String get type => 'utdPositionedDirectional';

  @override
  StacUtdPositionedDirectional getModel(Map<String, dynamic> json) =>
      StacUtdPositionedDirectional.fromJson(json);

  @override
  Widget parse(BuildContext context, StacUtdPositionedDirectional model) {
    final child = model.child;
    final rendered = child == null
        ? const SizedBox.shrink()
        : (Stac.fromJson(child, context) ?? const SizedBox.shrink());

    return PositionedDirectional(
      start: model.start,
      top: model.top,
      end: model.end,
      bottom: model.bottom,
      width: model.width,
      height: model.height,
      child: rendered,
    );
  }
}
