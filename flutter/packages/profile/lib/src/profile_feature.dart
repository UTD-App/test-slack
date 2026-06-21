import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/addons/app_feature.dart';
import 'package:utd_app/addons/ui_contribution.dart';
import 'package:utd_app/addons/widget_registry.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';

import 'presentation/widgets/mini_profile_card.dart';
import 'profile_routes.dart';
import 'profile_strings.dart';
import 'stac/profile_stac_sources.dart';

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
    // Register the `profile.user` Stac object source so UTD Studio screens that
    // bind to it render the signed-in user's profile.
    registerProfileStacSources();
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
    registry.register(
      'mini_profile_card',
      (context) => const MiniProfileCard(
        userId: 0,
        name: '',
      ),
    );
    // The base home screen renders the current user's own profile as its last
    // ("Me") tab via this seam, so the base never imports this package. The
    // current user id comes from the shared UserDataNotifier. The tab shows the
    // compact landing (avatar + identity, NO cover); tapping the avatar opens
    // the full profile (cover + data).
    registry.register(
      kSelfProfileWidget,
      (context) => ProfileRoutes.buildLandingPage(
        context.read<UserDataNotifier>().user.id ?? 0,
      ),
    );
  }

  @override
  Map<String, Map<String, String>> getTranslations() => profileTranslations;
}
