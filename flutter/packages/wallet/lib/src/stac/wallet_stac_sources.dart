import 'package:utd_app/shared/stac/stac_data_registry.dart';

import '../data/datasources/wallet_api_service.dart';
import '../data/repositories/wallet_repository_impl.dart';

/// Wires the wallet package's data into the Stac renderer for UTD Studio.
///
/// Exposes the signed-in user's coin balance as the single-object source
/// `wallet.balance`, consumed by a `Scope` (utdObject) on a Studio screen (e.g.
/// the coin card composed into `user_profile`). The returned map keys MUST match
/// the wallet manifest (backend/config/utd_manifest.php → coins) so the
/// designer's bindings resolve with no extra mapping. Mirrors profile.user.
///
/// Harmless no-op on a base whose StacDataRegistry is a stub (native LTP):
/// nothing consumes the source there. Called once from [WalletFeature.initialize].
void registerWalletStacSources() {
  final repository = WalletRepositoryImpl(WalletApiService());

  StacDataRegistry.instance.registerObject('wallet.balance', () async {
    final result = await repository.fetchBalances();
    final balances = result.dataOrNull ?? const [];

    double coins = 0;
    for (final b in balances) {
      if (b.currency == 'coins') {
        coins = b.balance;
        break;
      }
    }

    // String value: the Stac renderer loads it verbatim into a bound Text.
    return {'coins': coins.toStringAsFixed(0)};
  });
}
