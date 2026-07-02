import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/addons/app_feature.dart';
import 'package:utd_app/addons/ui_contribution.dart';
import 'package:utd_app/addons/widget_registry.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';

import 'profile_routes.dart';
import 'profile_strings.dart';

class ProfileFeature extends AppFeature {
  @override
  String get id => 'com.utd.profile';

  @override
  String get displayName => 'Profile';

  @override
  String get version => '1.0.0';

  /// Gated by the backend `profile` package: when the admin disables it from the
  /// dashboard, the app auto-disables this feature and the "Me" tab falls back to
  /// the base SelfProfileFallback instead of calling the unloaded profile routes.
  @override
  String? get packageSlug => 'profile';

  @override
  Future<void> initialize() async {
    // UTD Studio removed from the profile package: the profile renders fully
    // native (see AppShell / router), so no Stac data source is registered.
  }

  @override
  List<GoRoute> getRoutes() => ProfileRoutes.routes();

  @override
  List<UiContribution> getUiContributions() => const [
        // Profile is reached from Settings → Profile (route /user-profile/:id),
        // so it deliberately contributes NO bottom-nav tab. Not every installed
        // package belongs in the bottom bar.
      ];

  @override
  void registerWidgets(WidgetRegistry registry) {
    // The base home screen renders the current user's own profile as its last
    // ("Me") tab via this seam, so the base never imports this package. The
    // current user id comes from the shared UserDataNotifier. The tab shows the
    // compact landing (avatar + identity, NO cover); tapping the avatar opens
    // the full profile (cover + data).
    registry.register(
      kSelfProfileWidget,
      (context) {
        // Resolve the current user id from the persisted cache first (Hive,
        // populated synchronously at startup whenever a session exists), then
        // the in-memory notifier. This tab body is built EAGERLY inside the
        // shell's IndexedStack and kept alive, so it can render before the async
        // `/my-data` hydrate populates the notifier — reading the notifier alone
        // then yields id 0 → "User not found". The cache mirrors what the former
        // Studio `profile.user` source read, so behaviour matches the old path.
        final notifierId = context.read<UserDataNotifier>().user.id ?? 0;
        final cachedId =
            (CacheManager.getUserData()?['id'] as num?)?.toInt() ?? 0;
        return ProfileRoutes.buildLandingPage(
          notifierId > 0 ? notifierId : cachedId,
        );
      },
    );
  }

  @override
  Map<String, Map<String, String>> getTranslations() =>
      ProfileStrings.translations();
}
