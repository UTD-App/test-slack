import 'package:flutter/material.dart';

import '../addons/feature_registry.dart';
import '../addons/ui_contribution.dart';
import '../addons/ui_slot.dart';
import '../config/app_layout.dart';
import '../config/nav_icons.dart';
import '../shared/stac/stac_dynamic_screen.dart';

/// The server-driven home shell: builds the bottom navigation and tab bodies
/// from the [BottomNavConfig] delivered in the `app_layout` document, replacing
/// the native [FeatureRegistry]-built bar.
///
/// Each tab body is kept alive in an [IndexedStack]. A `stac` tab renders its
/// screen via [StacDynamicScreen]; a `native` tab reuses the feature's own
/// bottom-nav contribution (e.g. full-functionality chat / go-live) resolved by
/// `featureId`. The shell owns the ONLY bottom bar and adds no AppBar of its
/// own — each screen's AppBar comes from its published Stac scaffold.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.config,
    required this.registry,
  });

  final BottomNavConfig config;
  final FeatureRegistry registry;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selected = 0;

  List<NavTab> get _tabs => widget.config.tabs;

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    if (tabs.isEmpty) {
      return const Scaffold(body: Center(child: Text('لا توجد تبويبات.')));
    }
    if (_selected >= tabs.length) _selected = 0;
    final style = widget.config.style;

    return Scaffold(
      backgroundColor: style.bg,
      body: IndexedStack(
        index: _selected,
        children: [for (final t in tabs) _tabBody(t)],
      ),
      bottomNavigationBar: BottomAppBar(
        color: style.bg,
        padding: EdgeInsets.zero,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < tabs.length; i++) _navItem(tabs[i], i, style),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(NavTab tab, int index, NavStyle style) {
    final selected = index == _selected;
    final color = selected ? style.active : style.inactive;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selected = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(navIconFor(tab.iconName), color: color, size: 24),
            if (tab.label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tabBody(NavTab tab) {
    if (tab.isNative) {
      final builder = _nativeBuilder(tab.featureId);
      if (builder != null) return Builder(builder: builder);
      return Center(
        child: Text('تبويب native غير متاح: ${tab.featureId ?? tab.screen}'),
      );
    }
    return StacDynamicScreen(screenName: tab.screen);
  }

  /// Resolves a native bottom-nav contribution's builder by feature id (falls
  /// back to the first registered bottom-nav contribution).
  WidgetBuilder? _nativeBuilder(String? featureId) {
    final descriptors =
        widget.registry.getUiContributionDescriptors(UiSlot.bottomNav);
    if (descriptors.isEmpty) return null;
    UiContributionDescriptor? match;
    if (featureId != null) {
      for (final d in descriptors) {
        if (d.featureId == featureId) {
          match = d;
          break;
        }
      }
    }
    match ??= descriptors.first;
    return match.contribution.builder;
  }
}
