import 'package:flutter/material.dart';
import '../../addons/addons.dart';
import '../../localization/localization.dart';

/// Renders all UI contributions for a specific slot.
///
/// **Core responsibility**: Layout and composition of contributed widgets.
/// This widget owns the grid, spacing, and container styling.
///
/// **Feature responsibility**: Each contributed widget's content and behavior.
/// Features provide widgets; core arranges them.
///
/// When no features contribute to a slot, displays an empty container.
/// The core app can choose to hide empty slot renderers.
class UiSlotRenderer extends StatelessWidget {
  /// The slot to render contributions for
  final UiSlot slot;

  /// Features whose contributions to render
  final FeatureRegistry featureRegistry;

  /// Optional header text (e.g., "Home", "Dashboard")
  /// Null means no header is rendered
  final String? header;

  /// How to arrange contributed widgets
  final RenderMode renderMode;

  /// Layout behavior for contributed widgets
  final LayoutMode layoutMode;

  /// Spacing between widgets in pixels
  final double spacing;

  /// Padding around the slot content
  final EdgeInsets padding;

  const UiSlotRenderer({
    super.key,
    required this.slot,
    required this.featureRegistry,
    this.header,
    this.renderMode = RenderMode.column,
    this.layoutMode = LayoutMode.flex,
    this.spacing = 8.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final contributions = featureRegistry.getUiContributions(slot);

    // Render nothing if no contributions
    if (contributions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build widgets from contributions
    final widgets = contributions.map((c) => c.builder(context)).toList();

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional header
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  header!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Contributed widgets
          renderMode == RenderMode.column
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < widgets.length; i++) ...[
                      widgets[i],
                      if (i < widgets.length - 1) SizedBox(height: spacing),
                    ],
                  ],
                )
              : Wrap(spacing: spacing, runSpacing: spacing, children: widgets),
        ],
      ),
    );
  }
}

/// How to arrange contributed widgets
enum RenderMode {
  /// Stack widgets vertically
  column,

  /// Wrap widgets in a grid/flow
  wrap,
}

/// Layout behavior for widgets in flex containers
enum LayoutMode {
  /// Widgets share available space equally
  flex,

  /// Widgets use their intrinsic size
  intrinsic,
}

/// Renders contributions for the home slot.
///
/// **Core responsibility**: Home screen structure, scrolling, and layout.
/// The home slot is typically the primary content area.
class HomeSlotRenderer extends StatelessWidget {
  /// Features to render contributions from
  final FeatureRegistry featureRegistry;

  /// If true, wraps contributions in a scrollable area
  /// Use when you expect many contributions
  final bool scrollable;

  const HomeSlotRenderer({
    super.key,
    required this.featureRegistry,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final contributions = featureRegistry.getUiContributions(UiSlot.home);

    if (contributions.isEmpty) {
      // Core displays placeholder when no features contribute
      return Center(child: Text(context.tr('app.no_features')));
    }

    final widgets = contributions.map((c) => c.builder(context)).toList();

    // Core controls the scrolling behavior
    if (scrollable) {
      return SafeArea(
        child: SingleChildScrollView(child: Column(children: widgets)),
      );
    }

    return SafeArea(child: Column(children: widgets));
  }
}

/// Renders contributions for the dashboard slot.
///
/// **Core responsibility**: Grid layout, card containers, responsive design.
/// The dashboard slot typically displays multiple feature cards.
///
/// Features provide card content; core arranges them in a responsive grid.
class DashboardSlotRenderer extends StatelessWidget {
  /// Features to render contributions from
  final FeatureRegistry featureRegistry;

  /// Number of columns in the grid (responsive)
  final int crossAxisCount;

  /// Space between cards
  final double spacing;

  const DashboardSlotRenderer({
    super.key,
    required this.featureRegistry,
    this.crossAxisCount = 2,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final contributions = featureRegistry.getUiContributions(UiSlot.dashboard);

    if (contributions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build widgets from contributions - core wraps them in cards
    final cards = contributions.map((c) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: c.builder(context),
        ),
      );
    }).toList();

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.2,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

/// Renders contributions for the settings slot.
///
/// **Core responsibility**: Settings layout, grouping, navigation.
/// The settings slot typically displays feature configuration options.
///
/// Features provide settings widgets; core arranges them in a list.
class SettingsSlotRenderer extends StatelessWidget {
  /// Features to render contributions from
  final FeatureRegistry featureRegistry;

  /// Divider between feature settings
  final bool showDividers;

  const SettingsSlotRenderer({
    super.key,
    required this.featureRegistry,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final contributions = featureRegistry.getUiContributions(UiSlot.settings);

    if (contributions.isEmpty) {
      return const SizedBox.shrink();
    }

    final widgets = contributions.map((c) => c.builder(context)).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widgets.length,
      separatorBuilder: (context, index) =>
          showDividers ? const Divider() : const SizedBox.shrink(),
      itemBuilder: (context, index) => widgets[index],
    );
  }
}
