import 'package:go_router/go_router.dart';

import '../src/presentation/view/add_reel_page.dart';
import '../src/presentation/view/reels_feed_page.dart';
import '../src/presentation/view/reels_my_reels_page.dart';
import 'reels_strings.dart';

class ReelsRoutes {
  ReelsRoutes._();

  static const String feed = '/reels';
  static const String add = '/reels/add';

  /// A single user's reels grid. Build the path with [userReelsPath].
  static const String userReels = '/reels/user/:id';

  static String userReelsPath(int userId) => '/reels/user/$userId';

  static List<GoRoute> routes() => [
        GoRoute(
          path: feed,
          builder: (context, state) => const ReelsFeedPage(),
        ),
        GoRoute(
          path: add,
          builder: (context, state) => const AddReelPage(),
        ),
        GoRoute(
          path: userReels,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return ReelsMyReelsPage(userId: id, titleKey: ReelsStrings.myReels);
          },
        ),
      ];
}
