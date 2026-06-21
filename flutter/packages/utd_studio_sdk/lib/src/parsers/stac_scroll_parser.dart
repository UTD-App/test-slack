import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

/// Model for a vertical scroll container (UTD extension):
/// ```json
/// {
///   "type": "utdScroll",
///   "padding": 8,          // optional all-sides padding
///   "shrinkWrap": false,   // false → fills remaining height (Expanded) + scrolls
///                          // true  → sizes to content (use inside another scroll)
///   "reverse": false,
///   "child": { ...stac subtree (usually a column)... }
/// }
/// ```
///
/// The Studio has no scrollable static container otherwise: a plain `column`
/// overflows instead of scrolling once its content exceeds the viewport (e.g.
/// inside a `utdTabs` page, whose pages get no scroll of their own). `utdScroll`
/// wraps its `child` in a vertical [SingleChildScrollView] so hand-designed
/// (non data-bound) content scrolls — the counterpart of `utdList` for static
/// content, and the vertical counterpart of the horizontal `singleChildScrollView`
/// produced by the Studio's HScroll/Carousel.
class StacUtdScroll {
  const StacUtdScroll({
    required this.child,
    this.padding,
    this.shrinkWrap = false,
    this.reverse = false,
  });

  final Map<String, dynamic>? child;
  final double? padding;
  final bool shrinkWrap;
  final bool reverse;

  factory StacUtdScroll.fromJson(Map<String, dynamic> json) {
    return StacUtdScroll(
      child: (json['child'] as Map?)?.cast<String, dynamic>(),
      padding: (json['padding'] as num?)?.toDouble(),
      shrinkWrap: json['shrinkWrap'] as bool? ?? false,
      reverse: json['reverse'] as bool? ?? false,
    );
  }
}

/// Renders a `utdScroll`: its `child` inside a vertical [SingleChildScrollView].
/// Like `utdList`, when not `shrinkWrap` it wraps itself in an [Expanded] so it
/// takes the remaining space of its parent Column and scrolls (the common case:
/// a fixed header above a scrollable body inside a tab page). With `shrinkWrap`
/// it sizes to its content (for use inside an already-scrollable parent).
class StacUtdScrollParser extends StacParser<StacUtdScroll> {
  const StacUtdScrollParser();

  @override
  String get type => 'utdScroll';

  @override
  StacUtdScroll getModel(Map<String, dynamic> json) =>
      StacUtdScroll.fromJson(json);

  @override
  Widget parse(BuildContext context, StacUtdScroll model) {
    final child = model.child;
    if (child == null) return const SizedBox.shrink();

    final scroll = SingleChildScrollView(
      reverse: model.reverse,
      padding: model.padding != null
          ? EdgeInsets.all(model.padding!)
          : EdgeInsets.zero,
      child: Stac.fromJson(child, context) ?? const SizedBox.shrink(),
    );

    // When inside an unbounded parent (e.g. a Column / tab page), give the
    // scroll view a flexible slot instead of forcing the caller to wrap it.
    return model.shrinkWrap ? scroll : Expanded(child: scroll);
  }
}
