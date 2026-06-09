import 'package:flutter/material.dart';
import 'ui_slot.dart';

/// Represents a widget contribution to a specific UI slot.
///
/// This immutable data class pairs a UI slot with a widget builder function.
/// The builder is invoked at render time, allowing features to provide
/// context-aware or dynamic UI contributions.
///
/// Example:
/// ```dart
/// UiContribution(
///   slot: UiSlot.appBar,
///   builder: (context) => IconButton(
///     icon: const Icon(Icons.settings),
///     onPressed: () => context.push('/addon/settings'),
///   ),
/// )
/// ```
class UiContribution {
  /// The UI slot where this widget will be placed
  final UiSlot slot;

  /// Optional display label for admin/editor tools
  final String? label;

  /// Optional icons for navigation contributions (e.g., bottom nav)
  final Widget? activeIcon;

  /// Optional icons for navigation contributions (e.g., bottom nav)
  final Widget? inactiveIcon;

  /// Ordering within a slot (lower renders first)
  final int order;

  /// Function that builds the widget when needed
  /// Receives BuildContext for navigation, theme, and other context
  final WidgetBuilder builder;

  /// Creates a UI contribution for a specific slot.
  ///
  /// Both [slot] and [builder] are required.
  /// For [UiSlot.bottomNav], [activeIcon] and [inactiveIcon] are required.
  
  const UiContribution({
    required this.slot,
    required this.builder,
    this.label,
    this.activeIcon,
    this.inactiveIcon,
    this.order = 0,
  }) : assert(
          slot != UiSlot.bottomNav ||
              (activeIcon != null && inactiveIcon != null),
          'activeIcon and inactiveIcon are required for UiSlot.bottomNav',
        );
}

/// Descriptor used by admin tools to manage ordering.
class UiContributionDescriptor {
  final String key;
  final UiSlot slot;
  final String featureId;
  final String featureName;
  final UiContribution contribution;

  const UiContributionDescriptor({
    required this.key,
    required this.slot,
    required this.featureId,
    required this.featureName,
    required this.contribution,
  });

  String get label => contribution.label ?? featureName;
}
