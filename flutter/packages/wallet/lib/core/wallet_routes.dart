import 'package:go_router/go_router.dart';

import '../src/presentation/view/wallet_page.dart';

class WalletRoutes {
  WalletRoutes._();

  static const String wallet = '/wallet';

  static List<GoRoute> routes() => [
        GoRoute(
          path: wallet,
          builder: (context, state) => const WalletPage(),
        ),
      ];
}
