import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/gifts/gift_bridge.dart';
import 'package:utd_app/shared/profile/profile_navigator.dart';

import '../../../../core/moment_strings.dart';
import '../../../domain/entities/moment_entity.dart';
import '../../utils/media.dart';
import '../../utils/number_format.dart';
import '../../utils/reactions.dart';
import '../../utils/time.dart';
import 'cached_image.dart';
import 'expandable_text.dart';
import 'moment_avatar.dart';
import 'moment_share.dart';

/// A single Facebook-style moment card.
class MomentCard extends StatelessWidget {
  final MomentEntity moment;

  /// Set a reaction (tap = 'like', long-press picks one of the 6). Same type
  /// again toggles it off.
  final void Function(String reactionType) onReact;
  final VoidCallback onOpenLikes;
  final VoidCallback onOpenComments;
  final VoidCallback onReport;
  final VoidCallback onDelete;

  /// Opens the full-screen gallery at [index] for the moment's resolved [images].
  final void Function(List<String> images, int index) onTapImage;

  /// Called after a gift is successfully sent on this moment with the total COINS
  /// sent, so the parent can bump the moment's gift total without reloading the
  /// feed. Optional (e.g. Stac).
  final void Function(int coins)? onGiftSent;

  const MomentCard({
    super.key,
    required this.moment,
    required this.onReact,
    required this.onOpenLikes,
    required this.onOpenComments,
    required this.onReport,
    required this.onDelete,
    required this.onTapImage,
    this.onGiftSent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openProfile(context),
                    child: Row(
                      children: [
                        MomentAvatar(image: moment.userImage, name: moment.userName, radius: 21),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                moment.userName.isEmpty ? context.tr(MomentStrings.user) : moment.userName,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                timeAgo(moment.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onSelected: (v) {
                    if (v == 'report') onReport();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'report', child: Text(context.tr(MomentStrings.report))),
                    // Delete is only offered to the moment's author (backend `is_owner`).
                    if (moment.isOwner)
                      PopupMenuItem(value: 'delete', child: Text(context.tr(MomentStrings.delete))),
                  ],
                ),
              ],
            ),
          ),

          // text (clamps long posts with a "see more" toggle)
          if (moment.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: ExpandableText(moment.description, style: theme.textTheme.bodyLarge),
            ),

          // media collage (1/2/3/4+ layouts) with double-tap-to-like
          if (moment.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _MomentMedia(
                images: moment.images,
                onOpen: onTapImage,
                semanticLabel: moment.description.trim().isNotEmpty
                    ? moment.description.trim()
                    : context.tr(MomentStrings.imageA11y),
                onDoubleTapLike: () {
                  // Double-tap always "likes" (never un-likes), Instagram-style.
                  if (!moment.isLike) {
                    HapticFeedback.lightImpact();
                    onReact('like');
                  }
                },
              ),
            ),

          // actions — the original compact single row (reaction / comment / gift,
          // then "who liked" pushed to the end).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                // Reaction button: tap = like toggle, long-press = pick one of the
                // 6 reactions. Icon shows the user's reaction (or a default thumb)
                // and the label shows just the count — one icon, no duplicate thumb.
                Semantics(
                  button: true,
                  label: '${context.tr(MomentStrings.like)} ${moment.likeNum}',
                  onTap: () => onReact('like'),
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      onLongPress: () async {
                        final picked = await showReactionPicker(context);
                        if (picked != null) onReact(picked);
                      },
                      child: TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onReact('like');
                        },
                        icon: _reactionIcon(),
                        label: Text('${moment.likeNum}', style: const TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: '${context.tr(MomentStrings.comments)} ${moment.commentNum}',
                  onTap: onOpenComments,
                  child: ExcludeSemantics(
                    child: TextButton.icon(
                      onPressed: onOpenComments,
                      icon: const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 20),
                      label: Text('${moment.commentNum}', style: const TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
                // Gift button — only when the Gifts package is installed.
                if (GiftBridge.instance.isAvailable)
                  TextButton.icon(
                    onPressed: () => GiftBridge.instance.open(
                      context,
                      contextType: 'moment',
                      contextId: moment.id,
                      receiverName: moment.userName,
                      onSent: onGiftSent,
                    ),
                    icon: const Icon(Icons.card_giftcard, color: Colors.grey, size: 20),
                    // Total gift COINS on this moment, K-formatted (e.g. 22.5K).
                    label: Text(compactNumber(moment.giftsCoins), style: const TextStyle(color: Colors.grey)),
                  ),
                // Share the moment (text + first image) via the native sheet.
                IconButton(
                  onPressed: () => shareMoment(
                    context,
                    text: moment.description,
                    imagePaths: moment.images,
                  ),
                  icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
                  tooltip: context.tr(MomentStrings.share),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                TextButton(
                  onPressed: onOpenLikes,
                  child: Text(context.tr(MomentStrings.whoLiked), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the post author's profile via the base ProfileNavigator (rich
  /// Profile-package view when installed, base screen otherwise).
  void _openProfile(BuildContext context) {
    if (moment.userId > 0) {
      ProfileNavigator.open(context, userId: moment.userId);
    }
  }

  /// The current user's reaction emoji, or a default outline thumb when none.
  Widget _reactionIcon() {
    final r = reactionByType(moment.myReaction);
    if (r != null) return Text(r.emoji, style: const TextStyle(fontSize: 18));
    return const Icon(Icons.thumb_up_alt_outlined, color: Colors.grey, size: 20);
  }
}

/// The post's media: a smart collage (1 / 2 / 3 / 4+ layouts, with a "+N"
/// overlay past four) that double-taps to like (with a heart burst) and opens
/// the full-screen gallery on a single tap.
class _MomentMedia extends StatefulWidget {
  final List<String> images;

  /// Opens the gallery at [index] for the resolved image URLs.
  final void Function(List<String> images, int index) onOpen;

  /// Fired on double-tap (the card decides whether to actually like).
  final VoidCallback onDoubleTapLike;

  /// Screen-reader description for the images.
  final String semanticLabel;

  const _MomentMedia({
    required this.images,
    required this.onOpen,
    required this.onDoubleTapLike,
    required this.semanticLabel,
  });

  @override
  State<_MomentMedia> createState() => _MomentMediaState();
}

class _MomentMediaState extends State<_MomentMedia>
    with SingleTickerProviderStateMixin {
  static const double _gap = 2;

  late final List<String> _urls =
      widget.images.map(resolveMediaUrl).toList(growable: false);

  late final AnimationController _heart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _heart.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    HapticFeedback.lightImpact();
    widget.onDoubleTapLike();
    _heart.forward(from: 0);
  }

  Widget _cell(int i, {int extra = 0}) {
    final image = MomentNetworkImage(
      url: _urls[i],
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: widget.semanticLabel,
    );
    return GestureDetector(
      // onTap + onDoubleTap on the SAME detector (the reliable combination):
      // a single tap opens the gallery, a quick double-tap likes.
      onTap: () => widget.onOpen(_urls, i),
      onDoubleTap: _onDoubleTap,
      child: extra <= 0
          ? image
          : Stack(
              fit: StackFit.expand,
              children: [
                image,
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  alignment: Alignment.center,
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _collage() {
    final n = _urls.length;
    if (n == 1) {
      return AspectRatio(aspectRatio: 16 / 10, child: _cell(0));
    }
    if (n == 2) {
      return SizedBox(
        height: 220,
        child: Row(children: [
          Expanded(child: _cell(0)),
          const SizedBox(width: _gap),
          Expanded(child: _cell(1)),
        ]),
      );
    }
    if (n == 3) {
      return SizedBox(
        height: 240,
        child: Row(children: [
          Expanded(flex: 2, child: _cell(0)),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(children: [
              Expanded(child: _cell(1)),
              const SizedBox(height: _gap),
              Expanded(child: _cell(2)),
            ]),
          ),
        ]),
      );
    }
    // 4 or more: 2×2 grid, "+N" overlaid on the last tile.
    return SizedBox(
      height: 300,
      child: Column(children: [
        Expanded(
          child: Row(children: [
            Expanded(child: _cell(0)),
            const SizedBox(width: _gap),
            Expanded(child: _cell(1)),
          ]),
        ),
        const SizedBox(height: _gap),
        Expanded(
          child: Row(children: [
            Expanded(child: _cell(2)),
            const SizedBox(width: _gap),
            Expanded(child: _cell(3, extra: n - 4)),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _collage(),
          // Overlay must never intercept taps meant for the images below.
          IgnorePointer(child: _HeartBurst(controller: _heart)),
        ],
      ),
    );
  }
}

/// The white heart that pops and fades on a double-tap-to-like.
class _HeartBurst extends StatelessWidget {
  final AnimationController controller;
  const _HeartBurst({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        if (v == 0) return const SizedBox.shrink();
        // Fade in fast, hold, then fade out; scale with a soft overshoot.
        final opacity = v < 0.15
            ? v / 0.15
            : (v > 0.6 ? (1 - (v - 0.6) / 0.4).clamp(0.0, 1.0) : 1.0);
        final scale = 0.5 + 0.7 * Curves.easeOutBack.transform((v * 1.5).clamp(0.0, 1.0));
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 96,
              shadows: [Shadow(color: Colors.black45, blurRadius: 12)],
            ),
          ),
        );
      },
    );
  }
}
