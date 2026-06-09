import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/addons/ui_slot.dart';
import 'app_feature.dart';
import 'role_registry.dart';
import 'settings_registry.dart';
import 'ui_contribution.dart';
import 'user_data_extension.dart';
import 'widget_registry.dart';

/// Central registry for managing all enabled features in the application.
///
/// The FeatureRegistry:
/// - Holds the list of enabled [AppFeature] instances
/// - Aggregates routes from all features into a single list
/// - Collects UI contributions organized by [UiSlot]
/// - Manages the shared [WidgetRegistry] for custom widgets
/// - Handles feature initialization and disposal
///
/// The core app delegates to this registry for:
/// - Route configuration
/// - Feature-contributed UI rendering
/// - Widget registration and lookup
///
/// The registry gracefully handles zero features - the app functions
/// normally with just the core routes and UI.
///
/// Example usage:
/// ```dart
/// final registry = FeatureRegistry();
/// registry.addFeature(MyFeature());
/// registry.addFeature(AnotherFeature());
///
/// await registry.initializeAll();
/// final allRoutes = registry.aggregateRoutes();
/// final appBarWidgets = registry.getUiContributions(UiSlot.appBar);
/// ```
class FeatureRegistry extends ChangeNotifier {
  final List<AppFeature> _features = [];
  final Set<String> _disabledFeatureIds = {};
  final Map<String, String> _selectedContributions = {};
  final WidgetRegistry _widgetRegistry = WidgetRegistry();
  final RoleRegistry _roleRegistry = RoleRegistry();
  final SettingsRegistry _settingsRegistry = SettingsRegistry();
  final List<UserDataExtension> _userDataExtensions = [];
  final Map<String, int> _orderOverrides = {};
  Map<String, Map<String, String>>? _aggregatedTranslations;

  /// All registered features (both enabled and disabled).
  List<AppFeature> get allFeatures => List.unmodifiable(_features);

  /// Returns an unmodifiable list of enabled features.
  List<AppFeature> get features =>
      List.unmodifiable(_features.where((f) => !_disabledFeatureIds.contains(f.id)));

  /// Returns the set of disabled feature IDs.
  Set<String> get disabledFeatureIds => Set.unmodifiable(_disabledFeatureIds);

  bool isFeatureEnabled(String featureId) =>
      !_disabledFeatureIds.contains(featureId);

  void setDisabledFeatures(Set<String> ids) {
    _disabledFeatureIds
      ..clear()
      ..addAll(ids);
    _aggregatedTranslations = null;
    notifyListeners();
  }

  Map<String, String> get selectedContributions =>
      Map.unmodifiable(_selectedContributions);

  void setSelectedContributions(Map<String, String> selections) {
    _selectedContributions
      ..clear()
      ..addAll(selections);
    notifyListeners();
  }

  /// Returns all contribution descriptors for a specific feature across all slots.
  List<UiContributionDescriptor> getFeatureContributionDescriptors(
    String featureId,
  ) {
    final feature = _features.firstWhere((f) => f.id == featureId);
    final contributions = feature.getUiContributions();
    final descriptors = <UiContributionDescriptor>[];
    for (var i = 0; i < contributions.length; i++) {
      final c = contributions[i];
      final key = _buildContributionKey(featureId, c.slot, i);
      descriptors.add(
        UiContributionDescriptor(
          key: key,
          slot: c.slot,
          featureId: featureId,
          featureName: feature.displayName,
          contribution: c,
        ),
      );
    }
    return descriptors;
  }

  /// Returns the shared widget registry for all features.
  WidgetRegistry get widgetRegistry => _widgetRegistry;

  /// Returns the shared role registry for all features.
  RoleRegistry get roleRegistry => _roleRegistry;

  /// Returns the shared settings registry for all features.
  SettingsRegistry get settingsRegistry => _settingsRegistry;

  /// Returns all registered user data extensions.
  List<UserDataExtension> get userDataExtensions =>
      List.unmodifiable(_userDataExtensions);

  /// Adds a feature to the registry.
  ///
  /// The feature is added to the internal list but not yet initialized.
  /// Call [initializeAll] to initialize all registered features.
  ///
  /// Throws [ArgumentError] if a feature with the same ID already exists.
  void addFeature(AppFeature feature) {
    if (_features.any((f) => f.id == feature.id)) {
      throw ArgumentError(
        'Feature with ID "${feature.id}" is already registered',
      );
    }
    _features.add(feature);
  }

  /// Adds multiple features at once.
  void addFeatures(List<AppFeature> features) {
    for (final feature in features) {
      addFeature(feature);
    }
  }

  List<UiContributionDescriptor> getUiContributionDescriptors(UiSlot slot) {
    final descriptors = <UiContributionDescriptor>[];

    for (final feature in features) {
      final contributions = feature.getUiContributions();
      if (contributions.length <= 1) {
        // Single or no contribution — no filtering needed
        for (var i = 0; i < contributions.length; i++) {
          final contribution = contributions[i];
          if (contribution.slot != slot) continue;
          final key = _buildContributionKey(feature.id, slot, i);
          descriptors.add(
            UiContributionDescriptor(
              key: key,
              slot: slot,
              featureId: feature.id,
              featureName: feature.displayName,
              contribution: contribution,
            ),
          );
        }
        continue;
      }
      // Multiple contributions — use selection or default to first
      final selectedKey = _selectedContributions[feature.id] ??
          _buildContributionKey(feature.id, contributions.first.slot, 0);
      for (var i = 0; i < contributions.length; i++) {
        final contribution = contributions[i];
        if (contribution.slot != slot) continue;
        final key = _buildContributionKey(feature.id, slot, i);
        if (key != selectedKey) continue;
        descriptors.add(
          UiContributionDescriptor(
            key: key,
            slot: slot,
            featureId: feature.id,
            featureName: feature.displayName,
            contribution: contribution,
          ),
        );
      }
    }

    descriptors.sort(
      (a, b) => _effectiveOrder(a).compareTo(_effectiveOrder(b)),
    );

    return descriptors;
  }

  /// Validates all registered features for compatibility.
  ///
  /// Calls [AppFeature.validateCompatibility] on each feature.
  /// Returns a map of feature IDs to error messages for features
  /// that failed validation. Empty map means all valid.
  Map<String, String> validateAll() {
    final errors = <String, String>{};
    for (final feature in features) {
      final missingDeps = feature.dependencies
          .where((depId) => features.every((f) => f.id != depId))
          .toList();
      if (missingDeps.isNotEmpty) {
        errors[feature.id] = 'Missing dependencies: ${missingDeps.join(', ')}';
        continue;
      }
      final error = feature.validateCompatibility();
      if (error != null) {
        errors[feature.id] = error;
      }
    }
    return errors;
  }

  /// Initializes all registered features.
  ///
  /// This process happens in order:
  /// 1. Validate all features for compatibility
  /// 2. Initialize each feature (in registration order)
  /// 3. Register widgets from each feature
  ///
  /// If any feature initialization fails, the exception is propagated.
  /// Features initialized before the failure are not rolled back.
  Future<void> initializeAll() async {
    // Validate all features first
    final validationErrors = validateAll();
    if (validationErrors.isNotEmpty) {
      final messages = validationErrors.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      throw StateError('Feature validation failed:\n$messages');
    }

    // Initialize only enabled features
    for (final feature in features) {
      await feature.initialize();
    }

    // Register widgets for enabled features
    for (final feature in features) {
      feature.registerWidgets(_widgetRegistry);
    }

    // Register user data extensions
    for (final feature in features) {
      _userDataExtensions.addAll(feature.getUserDataExtensions());
    }

    // Register role definitions
    for (final feature in features) {
      _roleRegistry.registerRoles(feature.getRoleDefinitions());
    }

    // Register setting definitions
    for (final feature in features) {
      _settingsRegistry.registerSettings(feature.getSettingDefinitions());
    }
  }

  /// Disposes all registered features in reverse order.
  ///
  /// Called during app shutdown. Features are disposed in reverse
  /// registration order (LIFO) to handle dependencies correctly.
  Future<void> disposeAll() async {
    for (final feature in features.reversed) {
      await feature.dispose();
    }
  }

  /// Aggregates all routes from enabled features.
  ///
  /// Combines [AppFeature.getRoutes] from all registered features into
  /// a single list. Routes are in feature registration order.
  ///
  /// Returns an empty list if no features are registered or if
  /// features don't contribute any routes.
  List<GoRoute> aggregateRoutes() {
    final routes = <GoRoute>[];
    for (final feature in features) {
      routes.addAll(feature.getRoutes());
    }
    return routes;
  }

  /// Gets all UI contributions for a specific slot.
  ///
  /// Returns contributions in feature registration order.
  /// Multiple features can contribute to the same slot,
  /// and all contributions are returned.
  ///
  /// Returns an empty list if no contributions exist for the slot.
  List<UiContribution> getUiContributions(UiSlot slot) {
    final descriptors = getUiContributionDescriptors(slot);
    return descriptors.map((d) => d.contribution).toList();
  }

  /// Gets all UI contributions grouped by slot.
  ///
  /// Returns a map where keys are [UiSlot] values and values are
  /// lists of contributions for that slot (in registration order).
  ///
  /// Only slots with contributions are included in the map.
  Map<UiSlot, List<UiContribution>> getAllUiContributions() {
    final map = <UiSlot, List<UiContribution>>{};
    for (final slot in UiSlot.values) {
      final descriptors = getUiContributionDescriptors(slot);
      if (descriptors.isNotEmpty) {
        map[slot] = descriptors.map((d) => d.contribution).toList();
      }
    }
    return map;
  }

  /// Update ordering for contributions in a slot.
  void setContributionOrder(UiSlot slot, List<String> orderedKeys) {
    for (var i = 0; i < orderedKeys.length; i++) {
      _orderOverrides[orderedKeys[i]] = i;
    }
    notifyListeners();
  }

  /// Reset ordering overrides for a slot.
  void resetContributionOrder(UiSlot slot) {
    final keysToRemove = _orderOverrides.keys
        .where((key) => key.startsWith('${slot.name}::'))
        .toList();
    for (final key in keysToRemove) {
      _orderOverrides.remove(key);
    }
    notifyListeners();
  }

  int _effectiveOrder(UiContributionDescriptor descriptor) {
    return _orderOverrides[descriptor.key] ?? descriptor.contribution.order;
  }

  String _buildContributionKey(String featureId, UiSlot slot, int index) {
    return '${slot.name}::$featureId::$index';
  }

  /// Returns the merged translations from all features plus base translations.
  ///
  /// Merges [baseTranslations] with translations from every registered feature.
  /// The result is cached after the first call.
  ///
  /// In debug mode, logs a warning if two features provide the same key
  /// for the same locale (namespace collision).
  Map<String, Map<String, String>> aggregateTranslations(
    Map<String, Map<String, String>> baseTranslations,
  ) {
    if (_aggregatedTranslations != null) return _aggregatedTranslations!;

    final merged = <String, Map<String, String>>{};

    // Start with base translations
    for (final entry in baseTranslations.entries) {
      merged[entry.key] = Map<String, String>.from(entry.value);
    }

    // Merge each feature's translations
    for (final feature in features) {
      final featureTranslations = feature.getTranslations();
      for (final localeEntry in featureTranslations.entries) {
        final localeCode = localeEntry.key;
        merged.putIfAbsent(localeCode, () => {});
        // Warn on key collisions in debug mode
        if (kDebugMode) {
          for (final key in localeEntry.value.keys) {
            if (merged[localeCode]!.containsKey(key)) {
              debugPrint(
                'WARNING: Translation key "$key" in locale "$localeCode" '
                'from feature "${feature.id}" overwrites existing value.',
              );
            }
          }
        }
        merged[localeCode]!.addAll(localeEntry.value);
      }
    }

    _aggregatedTranslations = Map.unmodifiable(
      merged.map((k, v) => MapEntry(k, Map<String, String>.unmodifiable(v))),
    );
    return _aggregatedTranslations!;
  }

  /// Clears the cached translations. Call after dynamic feature changes.
  void invalidateTranslations() {
    _aggregatedTranslations = null;
  }

  // ── User Data Distribution ──────────────────────────────────────────

  /// Distributes incoming user data to all registered extensions.
  ///
  /// Each extension receives `fullResponse[extension.key]` if present.
  /// Also sets roles and settings from the response.
  void distributeUserData(Map<String, dynamic> fullResponse) {
    // Distribute to extensions
    for (final ext in _userDataExtensions) {
      ext.onDataReceived(fullResponse[ext.key] as Map<String, dynamic>?);
    }

    // Set roles from response
    final roles = fullResponse['roles'];
    if (roles is List) {
      _roleRegistry.setUserRoles(roles.cast<String>());
    }

    // Set settings from response
    final settings = fullResponse['settings'];
    if (settings is Map<String, dynamic>) {
      _settingsRegistry.setValues(settings);
    }
  }

  /// Clears all user data from extensions, roles, and settings.
  void clearAllUserData() {
    for (final ext in _userDataExtensions) {
      ext.onDataCleared();
    }
    _roleRegistry.clearUserRoles();
    _settingsRegistry.clearValues();
  }

  /// Serializes all extension data into a single map for caching.
  Map<String, dynamic> serializeAllUserData() {
    final result = <String, dynamic>{};
    for (final ext in _userDataExtensions) {
      final data = ext.serializeData();
      if (data != null) {
        result[ext.key] = data;
      }
    }
    result['roles'] = _roleRegistry.userRoleKeys.toList();
    result['settings'] = _settingsRegistry.allValues;
    return result;
  }

  /// Removes all features and clears registrations.
  ///
  /// Does not call [dispose] on features. Call [disposeAll] first
  /// if cleanup is needed.
  void clear() {
    _features.clear();
    _widgetRegistry.clear();
    _userDataExtensions.clear();
    _orderOverrides.clear();
    _aggregatedTranslations = null;
  }
}
