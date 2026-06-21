import 'package:go_router/go_router.dart';
import 'package:provider/single_child_widget.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart' show StacParser, StacActionParser;
import 'role_registry.dart';
import 'settings_registry.dart';
import 'ui_contribution.dart';
import 'user_data_extension.dart';
import 'widget_registry.dart';

/// Core interface for optional features in the add-on platform.
///
/// Every paid add-on must implement this interface to integrate with the core app.
/// This contract defines what a feature can contribute:
/// - Routes for navigation
/// - UI widgets at predefined slots
/// - Custom widget registrations
///
/// The app framework controls the layout and lifecycle. Features are responsible
/// only for their own logic and UI contributions.
///
/// Example implementation:
/// ```dart
/// class MyFeature extends AppFeature {
///   @override
///   String get id => 'com.example.myfeature';
///
///   @override
///   String get displayName => 'My Feature';
///
///   @override
///   List<GoRoute> getRoutes() => [
///     GoRoute(
///       path: '/feature/home',
///       builder: (context, state) => const MyFeatureHome(),
///     ),
///   ];
///
///   @override
///   List<UiContribution> getUiContributions() => [
///     UiContribution(
///       slot: UiSlot.appBar,
///       builder: (context) => const MyAppBarButton(),
///     ),
///   ];
///
///   @override
///   void registerWidgets(WidgetRegistry registry) {
///     registry.register('myCustomWidget', (context) => MyWidget());
///   }
/// }
/// ```
abstract class AppFeature {
  /// Unique identifier for this feature.
  /// Convention: reverse domain notation (e.g., 'com.company.feature')
  /// Used for logging, preferences, and avoiding conflicts.
  String get id;

  /// Human-readable name of this feature.
  /// Displayed in settings, about screens, and logs.
  String get displayName;

  /// Optional version number of the feature.
  /// Useful for compatibility checks and feature documentation.
  String get version => '1.0.0';

  /// Whether this is a core feature that cannot be disabled by users.
  /// Core features are hidden from the settings features list.
  bool get isCore => false;

  /// Feature dependencies by feature ID.
  /// Used by the core app to validate that required features are installed.
  List<String> get dependencies => const [];

  /// The backend package slug this feature is gated by (the `packages.slug`
  /// column / the `packages/<slug>` directory). When set, the app auto-disables
  /// this feature whenever the backend reports the package as disabled
  /// (`GET /packages/installed`), so an admin turning a package off from the
  /// dashboard makes the app behave as if it weren't installed — no calls to the
  /// package's (now-unloaded) routes.
  ///
  /// `null` (default) = a base / always-on feature (e.g. Auth, Notifications)
  /// with no backend package to gate it; it is never auto-disabled.
  String? get packageSlug => null;

  /// Returns all navigation routes this feature provides.
  ///
  /// Routes from all features are merged into a single GoRouter.
  /// Feature routes should use a path prefix to avoid conflicts:
  /// ```
  /// GoRoute(path: '/feature/$id/home', ...)
  /// ```
  ///
  /// Default implementation returns an empty list.
  List<GoRoute> getRoutes() => [];

  /// Returns all UI contributions this feature makes.
  ///
  /// Contributions are grouped by [UiSlot]. Multiple features can contribute
  /// to the same slot, and they will be rendered in order.
  ///
  /// Default implementation returns an empty list.
  List<UiContribution> getUiContributions() => [];

  /// Returns dependency providers this feature contributes.
  ///
  /// Providers are added to the app-level MultiProvider after initialization.
  /// Default implementation returns an empty list.
  List<SingleChildWidget> getProviders() => const [];

  /// Registers custom widgets this feature provides.
  ///
  /// Called during app initialization. The [registry] is shared across all features.
  /// Use a naming convention to avoid conflicts:
  /// ```
  /// registry.register('${id}_customWidget', builder);
  /// ```
  ///
  /// Default implementation does nothing.
  void registerWidgets(WidgetRegistry registry) {}

  /// Returns user data extensions this feature contributes.
  ///
  /// Each extension manages a namespaced section of user data
  /// (e.g., social stats, privacy settings). The [FeatureRegistry]
  /// distributes incoming API data to each extension by its key.
  ///
  /// Default implementation returns an empty list.
  List<UserDataExtension> getUserDataExtensions() => const [];

  /// Returns role definitions this feature contributes.
  ///
  /// Roles should use dot-namespaced keys to avoid collisions:
  /// ```dart
  /// [RoleDefinition(key: 'agency.agent', label: 'Agent')]
  /// ```
  ///
  /// Default implementation returns an empty list.
  List<RoleDefinition> getRoleDefinitions() => const [];

  /// Returns user setting definitions this feature contributes.
  ///
  /// Settings should use dot-namespaced keys:
  /// ```dart
  /// [UserSettingDefinition(key: 'privacy.hide_country', label: 'Hide Country', defaultValue: false)]
  /// ```
  ///
  /// Default implementation returns an empty list.
  List<UserSettingDefinition> getSettingDefinitions() => const [];

  /// Returns custom Stac **widget** parsers this feature contributes.
  ///
  /// Each parser maps a Stac `type` (e.g. a package widget like `chat.messages`)
  /// to a Flutter widget. Collected at startup and passed to `Stac.initialize`.
  /// Parsers MUST be stateless `const` and pull dependencies from the
  /// `BuildContext` at parse time.
  ///
  /// Default implementation returns an empty list.
  List<StacParser> getStacParsers() => const [];

  /// Returns custom Stac **action** parsers this feature contributes
  /// (an `actionType` → handler, e.g. `chat.openConversation`).
  ///
  /// Default implementation returns an empty list.
  List<StacActionParser> getStacActionParsers() => const [];

  /// Called when the feature is initialized.
  ///
  /// Use this for setup, validation, or checking dependencies.
  /// If initialization fails, throw an exception.
  ///
  /// Default implementation does nothing.
  Future<void> initialize() async {}

  /// Returns localized string translations this feature provides.
  ///
  /// The map structure is: `locale code → translation key → translated string`.
  /// Keys MUST be namespaced with a feature prefix to avoid collisions.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, Map<String, String>> getTranslations() => {
  ///   'en': {
  ///     'auth.login_title': 'Login',
  ///     'auth.login_button': 'Sign In',
  ///   },
  ///   'ar': {
  ///     'auth.login_title': 'تسجيل الدخول',
  ///     'auth.login_button': 'دخول',
  ///   },
  /// };
  /// ```
  ///
  /// Default implementation returns an empty map.
  Map<String, Map<String, String>> getTranslations() => const {};

  /// Called when the app is shutting down.
  ///
  /// Use this for cleanup, closing resources, or persisting state.
  /// The app waits for completion before continuing shutdown.
  ///
  /// Default implementation does nothing.
  Future<void> dispose() async {}

  /// Validates feature compatibility and dependencies.
  ///
  /// Return an error message if the feature cannot run on this app version.
  /// Useful for version compatibility checks or dependency validation.
  ///
  /// Returns null if validation passes.
  String? validateCompatibility() => null;
}
