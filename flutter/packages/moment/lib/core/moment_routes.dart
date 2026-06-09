import 'package:go_router/go_router.dart';

import '../src/presentation/view/add_moment_page.dart';
import '../src/presentation/view/moment_feed_page.dart';
import 'moment_strings.dart';

class MomentRoutes {
  MomentRoutes._();

  static const String feed = '/moment';
  static const String add = '/moment/add';

  /// A single user's posts. Build the path with [userMomentsPath].
  static const String userMoments = '/moment/user/:id';

  static String userMomentsPath(int userId) => '/moment/user/$userId';

  static List<GoRoute> routes() => [
        GoRoute(
          path: feed,
          builder: (context, state) => const MomentFeedPage(),
        ),
        GoRoute(
          path: add,
          builder: (context, state) => const AddMomentPage(),
        ),
        GoRoute(
          path: userMoments,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return MomentFeedPage(userId: id, titleKey: MomentStrings.posts);
          },
        ),
      ];
}
