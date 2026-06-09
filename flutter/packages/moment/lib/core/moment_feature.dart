import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:utd_app/addons/addons.dart';

import '../src/data/datasources/moment_api_service.dart';
import '../src/data/repositories/moment_repository_impl.dart';
import '../src/domain/repositories/moment_repository.dart';
import '../src/presentation/bloc/moment_feed/moment_feed_bloc.dart';
import '../src/presentation/view/moment_feed_page.dart';
import '../src/presentation/view/moment_profile_section.dart';
import 'moment_routes.dart';
import 'moment_strings.dart';

/// Moment feature — plugs the moments feed into the add-on platform.
///
/// Register it in the host app's `main.dart`:
/// ```dart
/// List<AppFeature> buildFeatures() => [ AuthFeature(), MomentFeature() ];
/// ```
class MomentFeature extends AppFeature {
  late final MomentApiService _api;
  late final MomentRepositoryImpl _repository;
  late final MomentFeedBloc _feedBloc;

  @override
  String get id => 'com.utd.moment';

  @override
  String get displayName => 'Moments';

  @override
  Future<void> initialize() async {
    _api = MomentApiService();
    _repository = MomentRepositoryImpl(_api);
    _feedBloc = MomentFeedBloc(_repository);
  }

  @override
  Future<void> dispose() async {
    await _feedBloc.close();
  }

  @override
  List<SingleChildWidget> getProviders() => [
        Provider<MomentRepository>.value(value: _repository),
        BlocProvider<MomentFeedBloc>.value(value: _feedBloc),
      ];

  @override
  List<GoRoute> getRoutes() => MomentRoutes.routes();

  @override
  List<UiContribution> getUiContributions() => [
        UiContribution(
          slot: UiSlot.bottomNav,
          label: MomentStrings.title,
          activeIcon: const Icon(Icons.dynamic_feed),
          inactiveIcon: const Icon(Icons.dynamic_feed_outlined),
          builder: (context) => const MomentFeedPage(),
        ),
        // Moments count on a user's profile (when Moment is installed).
        UiContribution(
          slot: UiSlot.userProfile,
          label: MomentStrings.title,
          order: 10,
          builder: (context) => const MomentProfileSection(),
        ),
      ];

  @override
  Map<String, Map<String, String>> getTranslations() => MomentStrings.translations();
}
