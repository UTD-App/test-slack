import 'package:flutter/material.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../core/reels_strings.dart';

/// One Facebook-style reaction. [type] is what the backend stores/expects.
/// The display name is resolved via `ReelsStrings.reactionLabelKey(type)` (so it
/// localizes); there is no static English label here.
class ReelReaction {
  final String type;
  final String emoji;
  const ReelReaction(this.type, this.emoji);
}

/// The 6 supported reactions, in display order. Order matters: the first one
/// ('like') is the default for a plain tap.
const reelReactions = <ReelReaction>[
  ReelReaction('like', '👍'),
  ReelReaction('love', '❤️'),
  ReelReaction('haha', '😂'),
  ReelReaction('wow', '😮'),
  ReelReaction('sad', '😢'),
  ReelReaction('angry', '😡'),
];

ReelReaction? reactionByType(String? type) {
  if (type == null || type.isEmpty) return null;
  for (final r in reelReactions) {
    if (r.type == type) return r;
  }
  return null;
}

/// A Facebook-style reaction trigger:
///  - a plain tap fires [onTapDefault] (the default 'like'),
///  - a long-press pops a reaction bar ANCHORED directly above [child]; while
///    holding, drag across the emojis — the one under the finger lifts and
///    scales up (and shows its name) — then release to pick it via [onSelected].
class ReactionPicker extends StatefulWidget {
  final Widget child;
  final VoidCallback onTapDefault;
  final ValueChanged<String> onSelected;
  const ReactionPicker({
    super.key,
    required this.child,
    required this.onTapDefault,
    required this.onSelected,
  });

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> {
  /// Per-emoji slot width inside the bar.
  static const double _item = 48;
  static const double _hPad = 8;
  static const double _vPad = 8;

  OverlayEntry? _entry;
  final ValueNotifier<int?> _highlight = ValueNotifier<int?>(null);

  /// Global rect of the bar (computed once, when it opens).
  Rect _bar = Rect.zero;

  @override
  void dispose() {
    _removeBar();
    _highlight.dispose();
    super.dispose();
  }

  /// Anchor the bar centered above the trigger (drops below only when there's no
  /// room above, e.g. a comment near the top of the sheet).
  void _showBar() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay = Overlay.of(context);

    final media = MediaQuery.of(context);
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;

    final barW = _item * reelReactions.length + _hPad * 2;
    final barH = _item + _vPad * 2;

    double left = origin.dx + size.width / 2 - barW / 2;
    left = left.clamp(8.0, media.size.width - barW - 8.0);

    double top = origin.dy - barH - 10;
    if (top < media.padding.top + 8) {
      top = origin.dy + size.height + 10; // no room above → drop below the trigger
    }

    _bar = Rect.fromLTWH(left, top, barW, barH);
    _highlight.value = null;
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
  }

  void _removeBar() {
    _entry?.remove();
    _entry = null;
  }

  /// Highlight the emoji under the finger as it drags across the bar. Dragging
  /// well below the bar (back toward the trigger) clears the selection.
  void _onMove(Offset g) {
    if (_entry == null) return;
    if (g.dy > _bar.bottom + 60 || g.dx < _bar.left || g.dx > _bar.right) {
      if (_highlight.value != null) _highlight.value = null;
      return;
    }
    final idx = ((g.dx - (_bar.left + _hPad)) / _item)
        .floor()
        .clamp(0, reelReactions.length - 1);
    if (_highlight.value != idx) _highlight.value = idx;
  }

  void _onEnd() {
    final idx = _highlight.value;
    _removeBar();
    if (idx != null) widget.onSelected(reelReactions[idx].type);
  }

  Widget _buildOverlay(BuildContext ctx) {
    return ValueListenableBuilder<int?>(
      valueListenable: _highlight,
      builder: (ctx, hi, _) {
        return Stack(
          children: [
            // The reaction bar.
            Positioned(
              left: _bar.left,
              top: _bar.top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).cardColor,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18)],
                  ),
                  // Force LTR so the visual order (👍…😡, left→right) always
                  // matches the left-based hit-test in [_onMove] — otherwise in
                  // an RTL app the row mirrors and the emoji that lights up isn't
                  // the one under the finger.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < reelReactions.length; i++)
                          SizedBox(
                            width: _item,
                            height: _item,
                            child: Center(
                              child: AnimatedSlide(
                                duration: const Duration(milliseconds: 120),
                                offset: hi == i ? const Offset(0, -0.45) : Offset.zero,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 120),
                                  scale: hi == i ? 1.5 : 1.0,
                                  child: Text(reelReactions[i].emoji, style: const TextStyle(fontSize: 30)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // The name label above the highlighted emoji.
            if (hi != null)
              Positioned(
                left: _bar.left + _hPad + hi * _item + _item / 2 - 50,
                width: 100,
                top: _bar.top - 38,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ctx.tr(ReelsStrings.reactionLabelKey(reelReactions[hi].type)),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTapDefault,
      onLongPressStart: (_) => _showBar(),
      onLongPressMoveUpdate: (d) => _onMove(d.globalPosition),
      onLongPressEnd: (_) => _onEnd(),
      onLongPressCancel: _removeBar,
      child: widget.child,
    );
  }
}
