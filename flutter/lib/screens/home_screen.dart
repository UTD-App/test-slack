import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../addons/feature_registry.dart';
import '../addons/ui_contribution.dart';
import '../addons/ui_slot.dart';
import '../localization/localization.dart';
import '../shared/core/color_manager.dart';
import '../shared/stac/stac_dynamic_screen.dart';
import '../shared/widgets/ui_slot_renderer.dart';
import 'settings_screen.dart';

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

    final bottomNavContributions = registry
        .getUiContributions(UiSlot.bottomNav)
        .toList();
    final drawerContributions = registry
        .getUiContributions(UiSlot.drawer)
        .toList();
    final homeContributions = registry.getUiContributions(UiSlot.home).toList();

    final hasHomeTab =
        drawerContributions.isNotEmpty || homeContributions.isNotEmpty;

    // Tab layout: [Home?] [bottomNav tabs...] [Settings]
    // Indices:     0 (if hasHomeTab)  →  bottomNav offset  →  settings last
    final bottomNavOffset = hasHomeTab ? 1 : 0;
    final settingsIndex = bottomNavOffset + bottomNavContributions.length;
    final totalTabs = settingsIndex + 1;

    if (_selectedIndex >= totalTabs) {
      _selectedIndex = 0;
    }

    final isHomeTab = hasHomeTab && _selectedIndex == 0;
    final isSettings = _selectedIndex == settingsIndex;

    return Scaffold(
      backgroundColor: colors.surface,
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
            activeIcon: Icons.settings,
            inactiveIcon: Icons.settings_outlined,
            label: 'Settings',
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
      return const StacDynamicScreen(
        screenName: 'core_settings',
        fallback: SettingsScreen(),
      );
    }

    if (isHomeTab) {
      if (homeContributions.isEmpty) {
        return const Center(child: Text('Home'));
      }
      return HomeSlotRenderer(featureRegistry: registry, scrollable: true);
    }

    final navIndex = _selectedIndex - bottomNavOffset;
    return bottomNavContributions[navIndex].builder(context);
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
  /// its top edge. A spacer is inserted in the middle of [navItems] to make
  /// room for the FAB.
  Widget _buildBottomBar({required List<Widget> navItems}) {
    final items = List<Widget>.from(navItems);
    items.insert((items.length / 2).ceil(), const SizedBox(width: 64));

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ColorManager.lumiaBgMedium,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: const Border(
              top: BorderSide(color: ColorManager.lumiaCardBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items,
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
              color: ColorManager.lumiaAccent.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
