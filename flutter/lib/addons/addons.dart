/// Public API for the add-ons system.
///
/// Import this single file to access the complete add-ons API:
/// - [AppFeature] - Interface for implementing features
/// - [FeatureRegistry] - Central registry for managing features
/// - [UiSlot] - Predefined UI contribution points
/// - [UiContribution] - Widget contribution to a UI slot
/// - [WidgetRegistry] - Registry for named custom widgets
library;

export 'app_feature.dart';
export 'feature_registry.dart';
export 'role_registry.dart';
export 'settings_registry.dart';
export 'ui_contribution.dart';
export 'ui_slot.dart';
export 'user_data_extension.dart';
export 'widget_registry.dart';
