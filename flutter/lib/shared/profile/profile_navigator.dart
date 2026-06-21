import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/addons/feature_registry.dart';
import 'package:utd_app/shared/notifiers/user_data_notifier.dart';

/// Opens the best available profile screen, keeping the package gating in ONE
/// place so call sites (Settings, Moment cards, …) never hardcode the route or
/// break when the Profile package isn't installed:
///
/// - Profile package installed (FeatureRegistry has `com.utd.profile`) → the
///   rich package view at `/user-profile/:id`.
/// - Not installed, OWN profile → the base edit screen `/profile`.
/// - Not installed, ANOTHER user → the base read-only [VisitedProfileFallback]
///   at `/user/:id` (a basic profile built from the always-available
///   `GET /users/{id}` endpoint), so visiting a profile still works without the
///   package.
class ProfileNavigator {
  ProfileNavigator._();

  static const String _profileFeatureId = 'com.utd.profile';

  static void open(BuildContext context, {int? userId}) {
    final installed = context
        .read<FeatureRegistry>()
        .features
        .any((f) => f.id == _profileFeatureId);

    if (installed && userId != null) {
      context.push('/user-profile/$userId');
      return;
    }

    final myId = context.read<UserDataNotifier>().user.id;
    if (userId == null || userId == myId) {
      context.push('/profile');
    } else {
      // No Profile package → show the base basic-profile fallback for the user.
      context.push('/user/$userId');
    }
  }
}
