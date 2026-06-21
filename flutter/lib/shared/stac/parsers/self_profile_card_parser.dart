import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

import '../../../addons/feature_registry.dart';
import '../../../addons/widget_registry.dart';
import '../../../screens/self_profile_fallback.dart';

/// Custom Stac widget `core.selfProfile`: renders the signed-in user's RICH
/// native profile landing (gradient avatar ring, camera badge, gender/level
/// badges, feature grid, avatar→full-profile, copy-ID) — the parts Stac
/// primitives can't express.
///
/// It is declared in the core manifest's `widgets` so UTD Studio can place it on
/// the profile screen: the screen stays server-driven (Studio composes it), but
/// this one node renders natively for a pixel-match with the standalone app.
///
/// The widget itself stays base-pure: it resolves the profile UI through the
/// [WidgetRegistry] seam ([kSelfProfileWidget], registered by the Profile
/// package) — the base never imports the package. Falls back to
/// [SelfProfileFallback] when the package is absent/disabled.
class SelfProfileCardParser extends StacParser<Map<String, dynamic>> {
  const SelfProfileCardParser();

  @override
  String get type => 'core.selfProfile';

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;

  @override
  Widget parse(BuildContext context, Map<String, dynamic> model) {
    final registry = context.read<FeatureRegistry>();
    return registry.widgetRegistry.build(kSelfProfileWidget, context) ??
        const SelfProfileFallback();
  }
}
