import 'package:flutter/material.dart';
import 'package:utd_app/config/app_theme.dart';

/// Full-screen gradient backdrop matching the app's dark-purple / live-app
/// aesthetic. Wrap a page body in this for the consistent background used
/// across onboarding, profile, and feature screens.
///
/// Defaults to the admin-controlled background gradient
/// ([AppThemeProvider.current.bgGradient], itself defaulting to the built-in
/// lumia gradient); pass explicit [colors] for a different look.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Always fill the parent so the gradient covers the full screen (including
    // behind the system status/navigation bars when used with extendBody) —
    // otherwise short content leaves an uncovered black strip at the bottom.
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors ?? AppThemeProvider.current.bgGradient,
            begin: begin,
            end: end,
          ),
        ),
        child: child,
      ),
    );
  }
}
