import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:utd_app/addons/addons.dart';
import 'package:utd_app/localization/localization.dart';

import '../src/data/datasources/wallet_api_service.dart';
import '../src/data/repositories/wallet_repository_impl.dart';
import '../src/domain/repositories/wallet_repository.dart';
import '../src/presentation/bloc/wallet_cubit.dart';
import '../src/presentation/view/wallet_profile_section.dart';
import '../src/stac/wallet_stac_sources.dart';
import 'wallet_routes.dart';
import 'wallet_strings.dart';

/// Wallet feature — plugs the user wallet (coins + dollar balances and
/// transaction history) into the add-on platform.
///
/// Register it in the host app's `main.dart`:
/// ```dart
/// List<AppFeature> buildFeatures() => [ AuthFeature(), MomentFeature(), WalletFeature() ];
/// ```
class WalletFeature extends AppFeature {
  late final WalletApiService _api;
  late final WalletRepositoryImpl _repository;
  late final WalletCubit _cubit;

  @override
  String get id => 'com.utd.wallet';

  @override
  String get displayName => 'Wallet';

  @override
  Future<void> initialize() async {
    _api = WalletApiService();
    _repository = WalletRepositoryImpl(_api);
    _cubit = WalletCubit(_repository);

    // UTD Studio: expose `wallet.balance` (coins) so a server-driven screen can
    // bind the coin card as Craft nodes. No-op on a native (non-Studio) base.
    registerWalletStacSources();
  }

  @override
  Future<void> dispose() async {
    await _cubit.close();
  }

  @override
  List<SingleChildWidget> getProviders() => [
        Provider<WalletRepository>.value(value: _repository),
        BlocProvider<WalletCubit>.value(value: _cubit),
      ];

  @override
  List<GoRoute> getRoutes() => WalletRoutes.routes();

  @override
  List<UiContribution> getUiContributions() => [
        // Coin-balance card on the user's OWN profile → opens the wallet page.
        // (Shown via UiSlot.userProfile so it appears on the user's own profile;
        // userProfileActions only renders on other users' profiles.)
        UiContribution(
          slot: UiSlot.userProfile,
          label: WalletStrings.title,
          order: 5,
          builder: (context) => const WalletProfileSection(),
        ),
        // Drawer entry so the wallet is also reachable from the home menu.
        UiContribution(
          slot: UiSlot.drawer,
          label: WalletStrings.title,
          builder: (context) => ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(context.tr(WalletStrings.title)),
            onTap: () {
              Navigator.of(context).maybePop();
              context.push(WalletRoutes.wallet);
            },
          ),
        ),
      ];

  @override
  Map<String, Map<String, String>> getTranslations() => WalletStrings.translations();
}
