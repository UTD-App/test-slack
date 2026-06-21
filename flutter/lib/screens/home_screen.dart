import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../addons/feature_registry.dart';
import '../addons/ui_contribution.dart';
import '../addons/ui_slot.dart';
import '../addons/widget_registry.dart';
import '../features/notifications/notification_bell.dart';
import '../localization/localization.dart';
import '../services/launch_gate_service.dart';
import '../shared/core/color_manager.dart';
import '../shared/widgets/ui_slot_renderer.dart';
import 'self_profile_fallback.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final registry = context.watch<FeatureRegistry>();
    final colors = Theme.of(context).colorScheme;

    // The last tab is always the current user's own profile ("Me"): the rich
    // Profile package view when installed, or a minimal account fallback
    // (ID / email / password + install hint) otherwise. The rich page is
    // resolved through the WidgetRegistry seam (kSelfProfileWidget) so the base
    // never imports the Profile package — packages depend on the base, never the
    // reverse.

    final bottomNavContributions = registry
        .getUiContributions(UiSlot.bottomNav)
        .toList();
    final drawerContributions = registry
        .getUiContributions(UiSlot.drawer)
        .toList();
    final homeContributions = registry.getUiContributions(UiSlot.home).toList();

    // The Home tab is always present: it's the app's landing page (top bar with
    // search + notifications) even when no package contributes home content.
    const hasHomeTab = true;

    // Tab layout: [Home] [bottomNav tabs...] [Settings]
    // Indices:     0    →  bottomNav offset  →  settings last
    const bottomNavOffset = 1;
    final settingsIndex = bottomNavOffset + bottomNavContributions.length;
    final totalTabs = settingsIndex + 1;

    if (_selectedIndex >= totalTabs) {
      _selectedIndex = 0;
    }

    final isHomeTab = _selectedIndex == 0;
    final isSettings = _selectedIndex == settingsIndex;

    return Scaffold(
      backgroundColor: colors.surface,
      extendBody: true,
      drawer: isHomeTab && drawerContributions.isNotEmpty
          ? _buildDrawer(drawerContributions, colors)
          : null,
      bottomNavigationBar: _buildBottomBar(
        navItems: [
          if (hasHomeTab)
            _buildNavItem(
              activeIcon: Icons.home,
              inactiveIcon: Icons.home_outlined,
              label: 'Home',
              isSelected: isHomeTab,
              colors: colors,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
          ..._buildBottomNavItems(
            bottomNavContributions,
            colors,
            bottomNavOffset,
          ),
          _buildNavItem(
            activeIcon: Icons.person,
            inactiveIcon: Icons.person_outline,
            label: 'app.me',
            isSelected: isSettings,
            colors: colors,
            onTap: () => setState(() => _selectedIndex = settingsIndex),
          ),
        ],
      ),
      body: _buildBody(
        isHomeTab: isHomeTab,
        isSettings: isSettings,
        bottomNavContributions: bottomNavContributions,
        homeContributions: homeContributions,
        registry: registry,
        bottomNavOffset: bottomNavOffset,
      ),
    );
  }

  Widget _buildBody({
    required bool isHomeTab,
    required bool isSettings,
    required List<UiContribution> bottomNavContributions,
    required List<UiContribution> homeContributions,
    required FeatureRegistry registry,
    required int bottomNavOffset,
  }) {
    if (isSettings) {
      // Last tab: the current user's own profile, supplied by a package through
      // the WidgetRegistry seam, or the minimal account fallback otherwise.
      return registry.widgetRegistry.build(kSelfProfileWidget, context) ??
          const SelfProfileFallback();
    }

    if (isHomeTab) {
      return _buildHomeTab(homeContributions, registry);
    }

    final navIndex = _selectedIndex - bottomNavOffset;
    return bottomNavContributions[navIndex].builder(context);
  }

  /// The landing page: a top bar (app name + search + notifications) above the
  /// home-slot content contributed by packages (or a friendly empty state).
  Widget _buildHomeTab(
    List<UiContribution> homeContributions,
    FeatureRegistry registry,
  ) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHomeTopBar(colors),
          Expanded(
            child: homeContributions.isEmpty
                ? _buildHomeEmptyState(colors)
                : HomeSlotRenderer(featureRegistry: registry, scrollable: true),
          ),
        ],
      ),
    );
  }

  /// Two small actions live at the top of the home page: search (opens the user
  /// search) and notifications (the bell carries the live unread badge).
  Widget _buildHomeTopBar(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppInfoProvider.current.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('app.search'),
            color: colors.onSurface,
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            tooltip: context.tr('notifications.title'),
            color: colors.onSurface,
            icon: const NotificationBell(),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeEmptyState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_outlined, size: 64, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              context.tr('app.welcome'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(List<UiContribution> contributions, ColorScheme colors) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colors.primaryContainer),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: contributions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    contributions[index].builder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBottomNavItems(
    List<UiContribution> contributions,
    ColorScheme colors,
    int offset,
  ) {
    return contributions.asMap().entries.map((entry) {
      final index = entry.key + offset;
      final contribution = entry.value;
      final isSelected = index == _selectedIndex;

      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedIndex = index),
          behavior: HitTestBehavior.opaque,
          child: _navContent(
            icon: isSelected
                ? contribution.activeIcon!
                : contribution.inactiveIcon!,
            label: contribution.label,
            isSelected: isSelected,
            colors: colors,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildNavItem({
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required bool isSelected,
    required ColorScheme colors,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: _navContent(
          icon: Icon(isSelected ? activeIcon : inactiveIcon),
          label: label,
          isSelected: isSelected,
          colors: colors,
        ),
      ),
    );
  }

  /// A nav item's icon + label. When selected, the (white) content is masked
  /// with the purple→pink gradient via [BlendMode.srcIn] (alpha-only), so it
  /// works regardless of the feature-provided icon's original color.
  Widget _navContent({
    required Widget icon,
    required String? label,
    required bool isSelected,
    required ColorScheme colors,
  }) {
    final fg = isSelected ? Colors.white : colors.onSurfaceVariant;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme.merge(
          data: IconThemeData(color: fg, size: 24),
          child: icon,
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            context.tr(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ],
    );

    if (!isSelected) return content;
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: ColorManager.navSelectedGradient,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: content,
    );
  }

  /// The rounded purple nav bar with a central live-button FAB overhanging
  /// its top edge. Items are split into a left and right half around a fixed
  /// centre gap, so the FAB stays centred for any number of tabs (3, 4, 5…).
  Widget _buildBottomBar({required List<Widget> navItems}) {
    final splitAt = (navItems.length / 2).ceil();
    final leftItems = navItems.sublist(0, splitAt);
    final rightItems = navItems.sublist(splitAt);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Frosted-glass bar: the body extends behind it (extendBody) so the
        // BackdropFilter blurs the page gradient/content through a translucent
        // fill — the mockup's glassy navigation look.
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 16,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorManager.lumiaCardBg.withValues(alpha: 0.60),
                      ColorManager.lumiaBgMedium.withValues(alpha: 0.62),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: const Border(
                    top: BorderSide(color: ColorManager.frostedBorder),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Row(children: leftItems)),
                        const SizedBox(width: 64),
                        Expanded(child: Row(children: rightItems)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(top: -22, child: _buildCenterFab()),
      ],
    );
  }

  Widget _buildCenterFab() {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('coming soon')),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: ColorManager.navSelectedGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: ColorManager.lumiaBgMedium, width: 4),
          boxShadow: [
            BoxShadow(
              color: ColorManager.lumiaAccent.withValues(alpha: 0.6),
              blurRadius: 18,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFFEC4899).withValues(alpha: 0.4),
              blurRadius: 26,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
