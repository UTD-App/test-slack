import 'package:utd_app/shared/stac/stac_data_registry.dart';
import 'package:utd_app/shared/stac/studio_slot_registry.dart';

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

/// Contributes the wallet's coin card to the server-driven **profile** screen,
/// the Studio analogue of the native `UiSlot.userProfile` card. The card is
/// appended to the profile screen's main column at render time (see
/// [StudioSlotRegistry] / [StacDynamicScreen]) — so installing the wallet makes
/// the card appear with NO edit to the profile screen (owned by the Profile
/// package) and nothing pushed to the server. Removing the package removes it.
///
/// The card is a `utdObject` bound to the `wallet.balance` source registered in
/// [registerWalletStacSources]; its coin value binds `wallet.balance.coins`, and
/// a tap opens the wallet page (`/wallet`) via the generic `core.navigate`
/// action. Keyed (`wallet.coins`) so re-running init never duplicates it.
///
/// No-op on a native (non-Studio) base: the registry is an unused map there, and
/// the native [UiContribution] for `UiSlot.userProfile` renders the card instead.
void registerWalletStudioCards() {
  StudioSlotRegistry.instance.contributeScreenCard(
    'profile',
    'wallet.coins',
    _walletCoinCardNode(),
  );
}

/// The coin card as a Stac subtree. Colors are AARRGGBB (`#AARRGGBB`), matching
/// the published Studio screens; `fontWeight` is the Stac string form (`w700`).
Map<String, dynamic> _walletCoinCardNode() => {
      'type': 'utdObject',
      'source': 'wallet.balance',
      'child': {
        'type': 'utdSized',
        'widthPercent': 92,
        'child': {
          'type': 'gestureDetector',
          'onTap': {
            'actionType': 'core.navigate',
            'route': '/wallet',
            'mode': 'push',
          },
          'child': {
            'type': 'container',
            'padding': 16,
            'decoration': {
              'type': 'boxDecoration',
              'gradient': {
                'type': 'linearGradient',
                'begin': 'topLeft',
                'end': 'bottomRight',
                'colors': ['#FFFF9D2F', '#FFFF6A2B'],
              },
              'borderRadius': 18,
            },
            'child': {
              'type': 'row',
              'spacing': 12,
              'mainAxisAlignment': 'start',
              'crossAxisAlignment': 'center',
              'children': [
                {
                  'type': 'container',
                  'width': 46,
                  'height': 46,
                  'alignment': 'center',
                  'decoration': {
                    'type': 'boxDecoration',
                    'color': '#33FFFFFF',
                    'borderRadius': 23,
                  },
                  'child': {
                    'type': 'icon',
                    'icon': 'monetization_on_rounded',
                    'size': 26,
                    'color': '#FFFFFFFF',
                  },
                },
                {
                  'type': 'expanded',
                  'child': {
                    'type': 'column',
                    'mainAxisSize': 'min',
                    'crossAxisAlignment': 'start',
                    'spacing': 2,
                    'children': [
                      {
                        'type': 'text',
                        'data': 'Coins',
                        'style': {
                          'type': 'textStyle',
                          'color': '#CCFFFFFF',
                          'fontSize': 13,
                          'fontWeight': 'w500',
                        },
                      },
                      {
                        'type': 'text',
                        'binding': 'wallet.balance.coins',
                        'data': '0',
                        'style': {
                          'type': 'textStyle',
                          'color': '#FFFFFFFF',
                          'fontSize': 22,
                          'fontWeight': 'w700',
                        },
                      },
                    ],
                  },
                },
                {
                  'type': 'icon',
                  'icon': 'chevron_right_rounded',
                  'size': 24,
                  'color': '#CCFFFFFF',
                },
              ],
            },
          },
        },
      },
    };
