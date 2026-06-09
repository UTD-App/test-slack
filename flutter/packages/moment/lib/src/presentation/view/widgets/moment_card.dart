import 'package:flutter/material.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/gifts/gift_bridge.dart';
import 'package:utd_app/shared/profile/profile_navigator.dart';

import '../../../../core/moment_strings.dart';
import '../../../domain/entities/moment_entity.dart';
import '../../utils/media.dart';
import '../../utils/time.dart';
import 'moment_avatar.dart';

/// A single Facebook-style moment card.
class MomentCard extends StatelessWidget {
  final MomentEntity moment;
  final VoidCallback onLike;
  final VoidCallback onOpenLikes;
  final VoidCallback onOpenComments;
  final VoidCallback onReport;
  final VoidCallback onDelete;
  final void Function(String url) onTapImage;

  /// Called after a gift is successfully sent on this moment, so the parent can
  /// bump the gift count without reloading the feed. Optional (e.g. Stac).
  final VoidCallback? onGiftSent;

  const MomentCard({
    super.key,
    required this.moment,
    required this.onLike,
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

          // text
          if (moment.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: Text(moment.description, style: theme.textTheme.bodyLarge),
            ),

          // images
          if (moment.images.isNotEmpty) _MomentImages(images: moment.images, onTap: onTapImage),

          // actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onLike,
                  icon: Icon(
                    moment.isLike ? Icons.favorite : Icons.favorite_border,
                    color: moment.isLike ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                  label: Text('${moment.likeNum}', style: const TextStyle(color: Colors.grey)),
                ),
                TextButton.icon(
                  onPressed: onOpenComments,
                  icon: const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 20),
                  label: Text('${moment.commentNum}', style: const TextStyle(color: Colors.grey)),
                ),
                // Gift button — only when the Gifts package is installed (wires
                // GiftBridge). Opens the gift picker for this moment.
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
                    label: Text('${moment.giftsCount}', style: const TextStyle(color: Colors.grey)),
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
}

class _MomentImages extends StatelessWidget {
  final List<String> images;
  final void Function(String url) onTap;
  const _MomentImages({required this.images, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget img(String path, {double? height}) {
      final url = resolveMediaUrl(path);
      return GestureDetector(
        onTap: () => onTap(url),
        child: Image.network(
          url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: height ?? 180,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: img(images.first, height: 300),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      children: [for (final p in images) ClipRRect(child: img(p, height: 160))],
    );
  }
}
