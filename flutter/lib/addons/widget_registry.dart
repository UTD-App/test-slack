import 'package:flutter/material.dart';

/// Well-known [WidgetRegistry] key: a package's builder for the *current user's*
/// own profile page, rendered as the home screen's last ("Me") tab.
///
/// The base renders this contribution when a package registers it and falls back
/// to the built-in Settings screen otherwise. This keeps the base self-contained:
/// it never imports any feature package — packages depend on the base, never the
/// reverse. The Profile package registers a builder under this key.
const String kSelfProfileWidget = 'profile.self';

/// Registry for custom widgets provided by features.
///
/// This allows features to register named widget builders that can be
/// referenced and instantiated elsewhere in the app. Useful for:
/// - Custom form inputs
/// - Feature-specific components
/// - Shared components across multiple UI slots
///
/// Usage:
/// ```dart
/// final registry = WidgetRegistry();
/// registry.register(
///   'myCustomWidget',
///   (context) => MyCustomWidget(),
/// );
///
/// // Later, retrieve and build
/// final widget = registry.build('myCustomWidget', context);
/// ```
class WidgetRegistry {
  final Map<String, WidgetBuilder> _widgets = {};

  /// Registers a widget builder with a unique name.
  ///
  /// Throws [ArgumentError] if a widget with the same name already exists.
  void register(String name, WidgetBuilder builder) {
    if (_widgets.containsKey(name)) {
      throw ArgumentError('Widget "$name" is already registered');
    }
    _widgets[name] = builder;
  }

  /// Builds a registered widget by name.
  ///
  /// Returns null if the widget name is not found.
  /// Consider this when building UI to provide fallbacks.
  Widget? build(String name, BuildContext context) {
    final builder = _widgets[name];
    return builder?.call(context);
  }

  /// Checks if a widget with the given name is registered.
  bool contains(String name) => _widgets.containsKey(name);

  /// Returns all registered widget names.
  List<String> get registeredWidgets => _widgets.keys.toList();

  /// Clears all registered widgets.
  void clear() => _widgets.clear();
}
