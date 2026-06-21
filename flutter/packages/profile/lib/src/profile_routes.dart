import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'data/profile_api_service.dart';
import 'data/profile_remote_datasource.dart';
import 'domain/profile_repository.dart';
import 'presentation/bloc/user_profile_bloc.dart';
import 'presentation/view/user_profile_page.dart';

class ProfileRoutes {
  static const String profile = '/user-profile/:id';

  static String profilePath(int userId) => '/user-profile/$userId';

  /// Path that opens a user's profile in read-only "visitor" mode. Used by the
  /// own-profile page so tapping your name/avatar previews exactly what another
  /// user sees when they open your profile (no edit affordances), even though
  /// the backend reports `is_me = true`.
  static String previewPath(int userId) => '/user-profile/$userId?preview=1';

  /// Builds the profile page wrapped in its own [UserProfileBloc]. Shared by
  /// the route and the bottom-nav "Profile" tab so the BLoC wiring lives in
  /// one place (the tab bypasses the route, so it can't rely on the route's
  /// provider).
  static Widget buildPage(
    int userId, {
    bool previewAsVisitor = false,
    bool summaryLanding = false,
  }) {
    return BlocProvider(
      create: (_) => UserProfileBloc(
        repository: ProfileRepositoryImpl(
          remoteDataSource: ProfileRemoteDataSourceImpl(
            apiService: ProfileApiService(),
          ),
        ),
      ),
      child: UserProfilePage(
        userId: userId,
        previewAsVisitor: previewAsVisitor,
        summaryLanding: summaryLanding,
      ),
    );
  }

  /// The compact "Me"-tab landing: avatar + name + ID (and the same package
  /// stats/badges) but NO cover, with a camera badge on the avatar to change
  /// the photo. Tapping the avatar opens the full profile (cover + data) via
  /// [profilePath].
  static Widget buildLandingPage(int userId) =>
      buildPage(userId, summaryLanding: true);

  static List<GoRoute> routes() => [
        GoRoute(
          path: profile,
          builder: (context, state) {
            final userId =
                int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            // `?preview=1` forces the read-only visitor view (own-profile
            // "preview as visitor").
            final preview = state.uri.queryParameters['preview'] == '1';
            return buildPage(userId, previewAsVisitor: preview);
          },
        ),
      ];
}
