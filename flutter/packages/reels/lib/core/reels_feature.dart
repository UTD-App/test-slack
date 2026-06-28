import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:utd_app/addons/addons.dart';
import 'package:utd_app/shared/profile/profile_view_arguments.dart';

import '../src/data/datasources/reels_api_service.dart';
import '../src/data/repositories/reels_repository_impl.dart';
import '../src/domain/repositories/reels_repository.dart';
import '../src/presentation/bloc/reels_feed/reels_feed_bloc.dart';
import '../src/presentation/view/reels_feed_page.dart';
import '../src/presentation/view/reels_my_reels_page.dart';
import 'reels_routes.dart';
import 'reels_strings.dart';

/// Reels feature — plugs the short-video feed into the add-on platform.
///
/// Register it in the host app's `main.dart`:
/// ```dart
/// List<AppFeature> buildFeatures() => [ AuthFeature(), MomentFeature(), ReelsFeature() ];
/// ```
class ReelsFeature extends AppFeature {
  late final ReelsApiService _api;
  late final ReelsRepositoryImpl _repository;
  late final ReelsFeedBloc _feedBloc;

  @override
  String get id => 'com.utd.reels';

  @override
  String get displayName => 'Reels';

  @override
  Future<void> initialize() async {
    _api = ReelsApiService();
    _repository = ReelsRepositoryImpl(_api);
    _feedBloc = ReelsFeedBloc(_repository);
  }

  @override
  Future<void> dispose() async {
    await _feedBloc.close();
  }

  @override
  List<SingleChildWidget> getProviders() => [
        Provider<ReelsRepository>.value(value: _repository),
        BlocProvider<ReelsFeedBloc>.value(value: _feedBloc),
      ];

  @override
  List<GoRoute> getRoutes() => ReelsRoutes.routes();

  @override
  List<UiContribution> getUiContributions() => [
        UiContribution(
          slot: UiSlot.bottomNav,
          label: ReelsStrings.title,
          activeIcon: const Icon(Icons.smart_display),
          inactiveIcon: const Icon(Icons.smart_display_outlined),
          builder: (context) => const ReelsFeedPage(),
        ),
        // A "Reels" tab on a visited user's profile, scoped to that user's reels.
        // Decoupled: appears only because this package is installed.
        UiContribution(
          slot: UiSlot.profileTab,
          label: ReelsStrings.title,
          order: 2,
          builder: (context) {
            int? userId;
            try {
              userId = context.read<ProfileViewArguments>().userId;
            } catch (_) {
              // Rendered outside a profile (no scope) → current user's reels.
            }
            return ReelsUserGrid(userId: userId);
          },
        ),
      ];

  @override
  Map<String, Map<String, String>> getTranslations() => ReelsStrings.translations();
}
