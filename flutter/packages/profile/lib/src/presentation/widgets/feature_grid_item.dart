import 'package:flutter/material.dart';

/// One entry in the profile feature grid. Provide EITHER an [assetIcon]
/// (a `packages/profile/...` image path) OR a [materialIcon] — not both.
/// [route] is optional; null means "not wired yet" (shows a coming-soon
/// snackbar on tap).
///
/// [featureId] gates the tile on a package: when set, the tile is shown ONLY if
/// a feature with that id is installed (registered in the FeatureRegistry), and
/// is hidden otherwise — it reappears automatically once the package is added.
/// null means an always-visible core tile.
class FeatureGridItem {
  final String labelKey;
  final String? assetIcon;
  final IconData? materialIcon;
  final String? route;
  final String? featureId;

  const FeatureGridItem({
    required this.labelKey,
    this.assetIcon,
    this.materialIcon,
    this.route,
    this.featureId,
  }) : assert(
          (assetIcon == null) != (materialIcon == null),
          'Provide exactly one of assetIcon or materialIcon',
        );
}
