import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

import '../core/stac_binding.dart';

/// One tab in a [StacUtdTabs].
///
/// The tab's *look* (active/inactive) comes from the shared
/// [StacUtdTabs.activeTemplate] / [StacUtdTabs.inactiveTemplate] designed once
/// for all tabs; each tab feeds its own [data] (`{ "text": .., "icon": .. }`)
/// into that template through `binding` (resolved by [StacBinding]). A tab may
/// optionally override the shared look with its own [active]/[inactive] design.
///
/// * [data]     — per-tab values (`text`, `icon`, …) bound inside the template.
/// * [active]   — optional per-tab override for the **selected** look.
/// * [inactive] — optional per-tab override for the **unselected** look.
/// * [page]     — the screen content shown when this tab is selected.
/// * [onTab]    — optional action fired on tap **instead of** switching the
///   page (e.g. `core.navigate` or `core.openDialog`). When set, the tab acts
///   as a button: the selection does not change and [page] is ignored.
class StacUtdTab {
  const StacUtdTab(
      {this.data, this.active, this.inactive, this.page, this.onTab});

  final Map<String, dynamic>? data;
  final Map<String, dynamic>? active;
  final Map<String, dynamic>? inactive;
  final Map<String, dynamic>? page;
  final Map<String, dynamic>? onTab;

  factory StacUtdTab.fromJson(Map<String, dynamic> json) {
    return StacUtdTab(
      data: (json['data'] as Map?)?.cast<String, dynamic>(),
      active: (json['active'] as Map?)?.cast<String, dynamic>(),
      inactive: (json['inactive'] as Map?)?.cast<String, dynamic>(),
      page: (json['page'] as Map?)?.cast<String, dynamic>(),
      onTab: (json['onTab'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// Model for a fully-customizable tabs node (UTD extension):
/// ```json
/// {
///   "type": "utdTabs",
///   "length": 3,
///   "initialIndex": 0,
///   "position": "top",          // top | bottom (horizontal bar)
///                               // left | right (vertical side bar)
///   "swipe": true,               // swipe between pages
///   "distribution": "fill",     // fill (equal share) | auto (natural size) | scroll
///   "alignment": "start",       // auto-mode main-axis alignment: start | center | end
///   "barBackground": "#1b1230", // optional bar background
///   "barPadding": 8,             // optional bar padding (all sides)
///   "barGap": 8,                 // optional spacing between adjacent tabs
///   "barSize": 56,               // optional bar thickness: height (horizontal) / width (vertical)
///   "activeTemplate":   { "type": "text", "binding": "text" },   // shared selected look
///   "inactiveTemplate": { "type": "text", "binding": "text" },   // shared unselected look
///   "tabs": [
///     { "data": { "text": "Home", "icon": "home" }, "page": {..},
///       "active": {..}, "inactive": {..} }   // active/inactive optional (per-tab override)
///   ]
/// }
/// ```
///
/// Unlike Stac's native `tabBar` (which only styles colors/labels), `utdTabs`
/// renders an **entire designed widget subtree** for each tab, swapping between
/// the active and inactive design as the selection changes. The look is a
/// **shared template** authored once; each tab supplies its `data` (text/icon)
/// resolved into the template via `binding`. A tab may override the shared look.
///
/// The bar can be laid out **horizontally** (`position: top|bottom`) or as a
/// **vertical side rail** (`position: left|right`). `distribution: scroll`
/// scrolls along the bar's main axis (horizontal for top/bottom, vertical for
/// left/right). `barSize` fixes the bar's thickness independently of the
/// widget's overall size, so the pages keep the remaining space.
class StacUtdTabs {
  const StacUtdTabs({
    required this.length,
    required this.tabs,
    this.initialIndex = 0,
    this.position = 'top',
    this.swipe = true,
    this.distribution = 'fill',
    this.alignment = 'start',
    this.barBackground,
    this.barPadding,
    this.barSize,
    this.barGap,
    this.activeTemplate,
    this.inactiveTemplate,
  });

  final int length;
  final List<StacUtdTab> tabs;
  final int initialIndex;
  final String position;
  final bool swipe;
  final String distribution;

  /// Tab alignment along the bar's main axis — only honoured in `auto`
  /// distribution (`start` | `center` | `end`).
  final String alignment;
  final String? barBackground;
  final double? barPadding;
  final double? barSize;

  /// Spacing (px) inserted between adjacent tab cells along the bar axis.
  final double? barGap;

  /// Shared per-state look authored once and reused for every tab (each tab's
  /// `data` is resolved into it via `binding`). A tab's own `active`/`inactive`
  /// overrides these when present.
  final Map<String, dynamic>? activeTemplate;
  final Map<String, dynamic>? inactiveTemplate;

  /// Vertical side rail when the bar sits on the left/right; otherwise a
  /// horizontal bar on top/bottom.
  bool get isVertical => position == 'left' || position == 'right';

  factory StacUtdTabs.fromJson(Map<String, dynamic> json) {
    final rawTabs = (json['tabs'] as List?) ?? const [];
    final tabs = rawTabs
        .whereType<Map>()
        .map((e) => StacUtdTab.fromJson(e.cast<String, dynamic>()))
        .toList();
    final length = (json['length'] as num?)?.toInt() ?? tabs.length;
    final initial = (json['initialIndex'] as num?)?.toInt() ?? 0;
    return StacUtdTabs(
      length: length < 1 ? 1 : length,
      tabs: tabs,
      initialIndex: initial.clamp(0, length < 1 ? 0 : length - 1),
      position: (json['position'] as String?) ?? 'top',
      swipe: json['swipe'] as bool? ?? true,
      distribution: (json['distribution'] as String?) ?? 'fill',
      alignment: (json['alignment'] as String?) ?? 'start',
      barBackground: json['barBackground'] as String?,
      barPadding: (json['barPadding'] as num?)?.toDouble(),
      barSize: (json['barSize'] as num?)?.toDouble(),
      barGap: (json['barGap'] as num?)?.toDouble(),
      activeTemplate: (json['activeTemplate'] as Map?)?.cast<String, dynamic>(),
      inactiveTemplate:
          (json['inactiveTemplate'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// Renders a `utdTabs`: a [DefaultTabController] driving a custom tab bar (which
/// swaps each tab's active/inactive design as the selection changes) and a
/// [TabBarView] of the per-tab pages. The bar and the pages share the same
/// controller, so tapping a tab and swiping a page stay in sync.
class StacUtdTabsParser extends StacParser<StacUtdTabs> {
  const StacUtdTabsParser();

  @override
  String get type => 'utdTabs';

  @override
  StacUtdTabs getModel(Map<String, dynamic> json) => StacUtdTabs.fromJson(json);

  @override
  Widget parse(BuildContext context, StacUtdTabs model) => _UtdTabs(model);
}

class _UtdTabs extends StatelessWidget {
  const _UtdTabs(this.model);

  final StacUtdTabs model;

  Widget _render(BuildContext context, Map<String, dynamic>? json) {
    if (json == null) return const SizedBox.shrink();
    return Stac.fromJson(json, context) ?? const SizedBox.shrink();
  }

  /// The design for a tab in the given state: the tab's own override if present,
  /// otherwise the shared template — with the tab's `data` resolved into it via
  /// `binding` (so the same template shows each tab's text/icon).
  Map<String, dynamic>? _designFor(StacUtdTab tab, bool selected) {
    final override = selected ? tab.active : tab.inactive;
    final shared = selected ? model.activeTemplate : model.inactiveTemplate;
    final design = override ?? shared;
    if (design == null) return null;
    final data = tab.data;
    if (data == null || data.isEmpty) return design;
    return StacBinding.resolve(design, data);
  }

  /// A single tab cell: renders the active or inactive design, and advances the
  /// controller on tap. In "fill" mode each cell expands to an equal share of
  /// the bar's main axis (works inside both a Row and a Column).
  Widget _tab(BuildContext context, TabController controller, int i,
      {required bool fill}) {
    final tab = i < model.tabs.length ? model.tabs[i] : const StacUtdTab();
    final selected = controller.index == i;
    final design = _designFor(tab, selected);

    // A tab with an `onTab` action behaves as a button: dispatch the action
    // (navigate / open dialog) instead of switching the page. We wrap the
    // design in a `gestureDetector` JSON so Stac routes the tap through the
    // registered action parsers — same path as utdList's `onItemTap`.
    final Widget cell;
    if (tab.onTab != null && design != null) {
      cell = Stac.fromJson({
            'type': 'gestureDetector',
            'onTap': tab.onTab,
            'child': design,
          }, context) ??
          const SizedBox.shrink();
    } else {
      cell = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.animateTo(i),
        child: _render(context, design),
      );
    }
    return fill ? Expanded(child: cell) : cell;
  }

  /// Builds the tab bar for either axis. [fillAllowed] is false when the parent
  /// height is unbounded (a vertical fill bar would need a bounded height for
  /// its Expanded children) — we then fall back to intrinsic-size cells.
  Widget _buildBar(BuildContext context, TabController controller,
      {required bool vertical, required bool fillAllowed}) {
    final useFill = model.distribution == 'fill' && fillAllowed;
    final gap = model.barGap ?? 0;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final cells = [
          for (var i = 0; i < model.length; i++)
            _tab(context, controller, i, fill: useFill),
        ];

        // Insert a fixed-size spacer between adjacent cells along the bar axis.
        // Spacers are a fixed size (not flex), so they don't interfere with the
        // intrinsic-size bounding used for the scroll axis.
        List<Widget> withGaps(List<Widget> items) {
          if (gap <= 0 || items.length < 2) return items;
          final out = <Widget>[];
          for (var i = 0; i < items.length; i++) {
            if (i > 0) {
              out.add(vertical ? SizedBox(height: gap) : SizedBox(width: gap));
            }
            out.add(items[i]);
          }
          return out;
        }

        Widget inner;
        if (model.distribution == 'scroll') {
          // Each cell is unbounded along the scroll axis (a horizontal scroll
          // gives infinite width, a vertical one infinite height). A tab design
          // that stretches on that axis (e.g. a Column with
          // `crossAxisAlignment: stretch`) would then force an infinite
          // constraint and crash layout. Bound every cell to its intrinsic size
          // along the scroll axis so such designs resolve instead of blowing up.
          final scrollCells = withGaps([
            for (final cell in cells)
              vertical ? IntrinsicHeight(child: cell) : IntrinsicWidth(child: cell),
          ]);
          inner = SingleChildScrollView(
            scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
            child: vertical
                ? Column(mainAxisSize: MainAxisSize.min, children: scrollCells)
                : Row(mainAxisSize: MainAxisSize.min, children: scrollCells),
          );
        } else if (model.distribution == 'auto') {
          // Natural-size cells laid out along the bar with the chosen main-axis
          // alignment (start/center/end) — no scroll, no equal-share stretch.
          final align = _mainAxisAlignment(model.alignment);
          final autoCells = withGaps(cells);
          inner = vertical
              ? Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: align,
                  children: autoCells,
                )
              : Row(mainAxisAlignment: align, children: autoCells);
        } else {
          inner = vertical
              ? Column(
                  mainAxisSize:
                      useFill ? MainAxisSize.max : MainAxisSize.min,
                  children: withGaps(cells),
                )
              : Row(children: withGaps(cells));
        }

        Widget bar = Container(
          color: _hex(model.barBackground),
          padding: model.barPadding != null
              ? EdgeInsets.all(model.barPadding!)
              : null,
          child: inner,
        );

        // Bar thickness is independent of the widget size: width when vertical,
        // height when horizontal.
        if (model.barSize != null) {
          bar = vertical
              ? SizedBox(width: model.barSize, child: bar)
              : SizedBox(height: model.barSize, child: bar);
        }
        return bar;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: model.length,
      initialIndex: model.initialIndex,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);
          final vertical = model.isVertical;

          return LayoutBuilder(
            builder: (context, constraints) {
              // TabBarView must live inside an Expanded, which requires a
              // bounded height. When the studio user drops utdTabs inside a
              // plain column/scroll view the incoming height is unbounded —
              // fall back to rendering only the selected page, shrink-wrapped,
              // instead of throwing and blanking the whole screen.
              if (!constraints.maxHeight.isFinite) {
                final page = AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => _render(
                    context,
                    controller.index < model.tabs.length
                        ? model.tabs[controller.index].page
                        : null,
                  ),
                );
                final bar = _buildBar(context, controller,
                    vertical: vertical, fillAllowed: false);

                if (vertical) {
                  final kids = model.position == 'left'
                      ? [Expanded(child: page), bar]
                      : [bar, Expanded(child: page)];
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: kids,
                    ),
                  );
                }
                final kids =
                    model.position == 'bottom' ? [page, bar] : [bar, page];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: kids,
                );
              }

              final pages = Expanded(
                child: TabBarView(
                  physics: model.swipe
                      ? null
                      : const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < model.length; i++)
                      _render(
                        context,
                        i < model.tabs.length ? model.tabs[i].page : null,
                      ),
                  ],
                ),
              );

              final bar = _buildBar(context, controller,
                  vertical: vertical, fillAllowed: true);

              if (vertical) {
                // RTL: first Row child sits at the start (right). bar on the
                // right → bar first; bar on the left → bar last.
                final kids = model.position == 'left'
                    ? [pages, bar]
                    : [bar, pages];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: kids,
                );
              }

              final kids =
                  model.position == 'bottom' ? [pages, bar] : [bar, pages];
              return Column(children: kids);
            },
          );
        },
      ),
    );
  }
}

/// Maps a UTD Studio alignment string to a Flutter [MainAxisAlignment].
MainAxisAlignment _mainAxisAlignment(String s) {
  switch (s) {
    case 'center':
      return MainAxisAlignment.center;
    case 'end':
      return MainAxisAlignment.end;
    default:
      return MainAxisAlignment.start;
  }
}

/// Parses a `#RRGGBB`/`#AARRGGBB` hex from UTD Studio; null when empty/invalid.
Color? _hex(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  var h = s.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}
