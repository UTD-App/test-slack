import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

/// Model for a percentage-of-screen sized node:
/// ```json
/// {
///   "type": "utdSized",
///   "widthPercent": 80,   // optional, 1..100 — % of screen width
///   "heightPercent": 80,  // optional, 1..100 — % of screen height
///   "child": { ...stac subtree... }
/// }
/// ```
class StacUtdSized {
  const StacUtdSized({this.widthPercent, this.heightPercent, this.child});

  final double? widthPercent;
  final double? heightPercent;
  final Map<String, dynamic>? child;

  factory StacUtdSized.fromJson(Map<String, dynamic> json) {
    return StacUtdSized(
      widthPercent: (json['widthPercent'] as num?)?.toDouble(),
      heightPercent: (json['heightPercent'] as num?)?.toDouble(),
      child: (json['child'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// Renders a `utdSized`: sizes its [child] to a percentage of the **screen**
/// (via [MediaQuery]). Authored in UTD Studio via the "نسبة مئوية" size mode —
/// e.g. a messages list at 80% of screen height.
///
/// The scalar/percentage counterpart of the serializer's `expanded` (fill) and
/// `container.width/height` (fixed px). Percentages are clamped to 1..100.
///
/// ⚠️ Percent is of the full screen, not the available area — if header +
/// composer + percent > 100% the content can overflow. Prefer fill (Expanded)
/// when the goal is simply "take the remaining space".
class StacUtdSizedParser extends StacParser<StacUtdSized> {
  const StacUtdSizedParser();

  @override
  String get type => 'utdSized';

  @override
  StacUtdSized getModel(Map<String, dynamic> json) =>
      StacUtdSized.fromJson(json);

  @override
  Widget parse(BuildContext context, StacUtdSized model) {
    final child = model.child;
    if (child == null) return const SizedBox.shrink();

    final rendered = Stac.fromJson(child, context) ?? const SizedBox.shrink();

    final screen = MediaQuery.of(context).size;
    final wp = model.widthPercent;
    final hp = model.heightPercent;
    final width = wp != null ? screen.width * (wp.clamp(0, 100) / 100) : null;
    final height = hp != null ? screen.height * (hp.clamp(0, 100) / 100) : null;

    if (width == null && height == null) return rendered;
    return SizedBox(width: width, height: height, child: rendered);
  }
}
