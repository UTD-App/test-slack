import 'package:go_router/go_router.dart';

import '../src/presentation/view/gift_history_page.dart';

class GiftsRoutes {
  GiftsRoutes._();

  static const String history = '/gifts/history';

  static List<GoRoute> routes() => [
        GoRoute(
          path: history,
          builder: (context, state) => const GiftHistoryPage(),
        ),
      ];
}
