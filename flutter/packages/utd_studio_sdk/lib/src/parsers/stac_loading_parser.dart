import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

/// Model for a loading indicator (UTD extension):
/// ```json
/// { "type": "utdLoading", "color": "#ffffff", "size": 28, "strokeWidth": 3 }
/// ```
///
/// A purely visual, indeterminate progress indicator the designer drops onto
/// startup / splash screens from UTD Studio. The Base owns *when* the loading
/// ends (data prefetch + version/update checks) and navigates away — this widget
/// only *represents* the loading state. (Future: swap the spinner for a real
/// loading animation — the "Mutable Stack" phase.)
class StacUtdLoading {
  const StacUtdLoading({this.color, this.size = 28, this.strokeWidth = 3});

  final Color? color;
  final double size;
  final double strokeWidth;

  factory StacUtdLoading.fromJson(Map<String, dynamic> json) {
    return StacUtdLoading(
      color: _hex(json['color'] as String?),
      size: (json['size'] as num?)?.toDouble() ?? 28,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3,
    );
  }
}

/// Renders a `utdLoading`: a [CircularProgressIndicator] sized to `size` and
/// tinted with `color` (defaults to the theme's primary color). Self-constrained
/// so it sits safely inside a Column/Row without forcing unbounded layout.
class StacUtdLoadingParser extends StacParser<StacUtdLoading> {
  const StacUtdLoadingParser();

  @override
  String get type => 'utdLoading';

  @override
  StacUtdLoading getModel(Map<String, dynamic> json) =>
      StacUtdLoading.fromJson(json);

  @override
  Widget parse(BuildContext context, StacUtdLoading model) {
    final color = model.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: model.size,
      height: model.size,
      child: CircularProgressIndicator(
        strokeWidth: model.strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Parses a `#RRGGBB`/`#AARRGGBB` hex from UTD Studio; null when empty/invalid.
Color? _hex(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  var h = s.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}
