import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

import '../../../addons/feature_registry.dart';

/// Custom Stac widget `wallet.card`: renders the Wallet package's coin-balance
/// card on a server-driven (UTD Studio) screen.
///
/// test-slack composes the profile/home screen from Studio nodes, which replaces
/// the native landing and so never picks up the wallet's [UiSlot.userProfile]
/// contribution. Declaring this node in the Studio screen places the wallet card
/// back. Stays base-pure: it resolves the card through the [WidgetRegistry] seam
/// (`wallet.card`, registered by `WalletFeature.registerWidgets`) — no wallet
/// import here. Renders nothing when the Wallet package is absent/disabled.
class WalletCardParser extends StacParser<Map<String, dynamic>> {
  const WalletCardParser();

  @override
  String get type => 'wallet.card';

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;

  @override
  Widget parse(BuildContext context, Map<String, dynamic> model) {
    final registry = context.read<FeatureRegistry>();
    return registry.widgetRegistry.build('wallet.card', context) ??
        const SizedBox.shrink();
  }
}
