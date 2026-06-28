import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../addons/feature_registry.dart';
import '../addons/ui_contribution.dart';
import '../addons/ui_slot.dart';
import '../addons/widget_registry.dart';
import '../config/app_layout.dart';
import '../config/nav_icons.dart';
import '../localization/localization.dart';
import '../shared/core/color_manager.dart';
import '../shared/widgets/gradient_background.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';
import 'self_profile_fallback.dart';

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
      // Transparent + extendBody so the dark-purple gradient flows edge-to-edge
      // behind BOTH system bars (status bar on top, the transparent system nav
      // under the frosted menu). Replaces the old opaque `style.bg` chrome that
      // rendered black bars top & bottom.
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GradientBackground(
        // SafeArea (top only) so server-driven tab bodies don't render under the
        // status bar — their Stac scaffolds have no AppBar, so without this the
        // first widget (e.g. the profile avatar) jams into the status bar.
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selected,
            children: [for (final t in tabs) _tabBody(t)],
          ),
        ),
      ),
      bottomNavigationBar: _frostedBottomBar(tabs, style),
    );
  }

  /// Frosted, translucent bottom bar that floats over the gradient (matches the
  /// reference design) instead of an opaque dark band.
  Widget _frostedBottomBar(List<NavTab> tabs, NavStyle style) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: ColorManager.frostedFill,
            border: Border(
              top: BorderSide(color: ColorManager.frostedBorder),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    _navItem(tabs[i], i, style),
                ],
              ),
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
                // Nav labels go through translation: a key (e.g. "app.home")
                // localizes; a plain literal passes through unchanged (context.tr
                // returns its input when it isn't a catalog key).
                context.tr(tab.label),
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

  /// Server nav tabs authored as `stac` that are actually owned by a NATIVE
  /// package feature (a full-functionality screen primitives can't host — e.g.
  /// the audio-room). Maps the tab `screen` → the feature id whose bottom-nav
  /// contribution renders it. Falls back to the published Stac screen when the
  /// package isn't installed/enabled. (Without this, a Studio app_layout that
  /// marks the tab `stac` would show our placeholder instead of the real screen.)
  static const Map<String, String> _nativeScreenFeatures = {
    'audio': 'com.utd.audio_room',
    // The moments feed (tab `screen: "feed"`) is a full-functionality screen —
    // reactions, comment/likes sheets, gift sending, image preview, infinite
    // scroll, pull-to-refresh — that the Studio `feed` screen's `utdList`
    // (source `moment.feed`) can't host (no native data source/actions are
    // registered for it → empty/blank body). Render the package's native
    // MomentFeedPage instead; falls back to the published Stac screen when the
    // Moment package isn't installed/enabled.
    'feed': 'com.utd.moment',
  };

  Widget _tabBody(NavTab tab) {
    if (tab.isNative) {
      final builder = _nativeBuilder(tab.featureId);
      if (builder != null) return Builder(builder: builder);
      return Center(
        child: Text('تبويب native غير متاح: ${tab.featureId ?? tab.screen}'),
      );
    }
    // A `stac` tab whose screen is owned by a native package feature → render the
    // feature's real screen (STRICT match: only when that exact feature is
    // present/enabled; otherwise fall through to the published Stac screen).
    final nativeFeatureId = _nativeScreenFeatures[tab.screen];
    if (nativeFeatureId != null) {
      for (final d
          in widget.registry.getUiContributionDescriptors(UiSlot.bottomNav)) {
        if (d.featureId == nativeFeatureId) {
          return Builder(builder: d.contribution.builder);
        }
      }
    }
    // The self-profile screen is too rich for Stac primitives (gradient avatar
    // ring, camera badge, gender/level badges, feature grid, avatar→full-profile,
    // copy-ID). Render the package's NATIVE landing via the WidgetRegistry seam —
    // identical to the standalone app, same /users/{id}/profile data + behaviours
    // — falling back to the base placeholder when the Profile package is absent.
    if (tab.screen == 'user_profile' || tab.screen == 'profile') {
      // Server-driven (Studio composes the screen and places the rich
      // `profile.card` widget — see ProfileCardParser), with the package's native
      // landing as a FALLBACK until the screen is published / if offline.
      return StacDynamicScreen(
        screenName: tab.screen,
        fallback: Builder(
          builder: (context) =>
              widget.registry.widgetRegistry.build(kSelfProfileWidget, context) ??
                  const SelfProfileFallback(),
        ),
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
