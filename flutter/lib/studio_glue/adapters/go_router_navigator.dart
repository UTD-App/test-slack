import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/config/app_flow.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// [AppNavigator] over `go_router`, preserving the exact context-based routing
/// the core actions used before (`context.push` / `go` / `pushReplacement` /
/// `pop`). `home` resolves from the active [AppFlow] for `core.back`'s fallback.
class GoRouterNavigator implements AppNavigator {
  const GoRouterNavigator();

  @override
  void push(BuildContext context, String route, {Object? extra}) =>
      context.push(route, extra: extra);

  @override
  void replace(BuildContext context, String route, {Object? extra}) =>
      context.pushReplacement(route, extra: extra);

  @override
  void go(BuildContext context, String route, {Object? extra}) =>
      context.go(route, extra: extra);

  @override
  bool canPop(BuildContext context) => context.canPop();

  @override
  void pop(BuildContext context) => context.pop();

  @override
  String get home => AppFlow.instance.home;
}
