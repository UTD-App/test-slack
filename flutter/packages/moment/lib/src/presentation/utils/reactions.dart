import 'package:flutter/material.dart';

/// One Facebook-style reaction. [type] is what the backend stores/expects;
/// the localized display word comes from `MomentStrings.reactionLabelKey`.
class MomentReaction {
  final String type;
  final String emoji;
  const MomentReaction(this.type, this.emoji);
}

/// The 6 supported reactions, in display order. Order matters: the first one
/// ('like') is the default for a plain tap.
const momentReactions = <MomentReaction>[
  MomentReaction('like', '👍'),
  MomentReaction('love', '❤️'),
  MomentReaction('haha', '😂'),
  MomentReaction('wow', '😮'),
  MomentReaction('sad', '😢'),
  MomentReaction('angry', '😡'),
];

MomentReaction? reactionByType(String? type) {
  if (type == null || type.isEmpty) return null;
  for (final r in momentReactions) {
    if (r.type == type) return r;
  }
  return null;
}

/// Long-press popup: a horizontal row of the 6 reactions. Returns the chosen
/// type, or null if dismissed.
Future<String?> showReactionPicker(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.08),
    builder: (ctx) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in momentReactions)
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pop(ctx, r.type),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(r.emoji, style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
