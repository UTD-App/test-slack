import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/profile/profile_view_arguments.dart';

import '../../../core/gifts_strings.dart';
import '../utils/media.dart';

/// Profile section contributed by the Gifts package, shown ONLY when visiting
/// someone else's profile (self-hides on the viewer's own profile). It reads the
/// already-loaded `sections.gifts` from ProfileViewArguments (no extra call) and
/// renders, when present:
///   • Top supporters — who spent the most gifting this user.
///   • Received gifts wall.
///   • Gifts sent wall.
/// The sender/receiver LEVEL badges are rendered elsewhere (ProfileIdentity).
class GiftsProfileSection extends StatelessWidget {
  const GiftsProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    ProfileViewArguments? args;
    try {
      args = context.read<ProfileViewArguments>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    // Visited-only — leave the viewer's own profile untouched.
    if (args.isMe) return const SizedBox.shrink();

    final section = args.section('gifts');
    final received = (section['items'] as List?) ?? const [];
    final sent = (section['sent'] as List?) ?? const [];
    final supporters = (section['top_supporters'] as List?) ?? const [];

    final cards = <Widget>[
      if (supporters.isNotEmpty) _supportersCard(context, supporters),
      if (received.isNotEmpty)
        _giftsCard(context, GiftsStrings.received, received, Icons.card_giftcard),
      if (sent.isNotEmpty)
        _giftsCard(context, GiftsStrings.giftsSent, sent, Icons.send_rounded),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(mainAxisSize: MainAxisSize.min, children: cards);
  }

  Widget _supportersCard(BuildContext context, List supporters) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.favorite, size: 18, color: Colors.pinkAccent),
              const SizedBox(width: 6),
              Text(context.tr(GiftsStrings.topSupporters),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: supporters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final raw = supporters[i];
                  if (raw is! Map) return const SizedBox.shrink();
                  return _SupporterTile(item: raw.cast<String, dynamic>());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _giftsCard(
      BuildContext context, String titleKey, List items, IconData icon) {
    final theme = Theme.of(context);
    final count = items.fold<int>(
      0,
      (sum, e) => sum + ((e is Map ? (e['num'] as num?)?.toInt() : 0) ?? 0),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(context.tr(titleKey),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('$count',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final raw in items)
                  if (raw is Map) _GiftTile(item: raw.cast<String, dynamic>()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One top-supporter: avatar + coins-spent + name, tapping opens their profile.
class _SupporterTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _SupporterTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = (item['user_id'] as num?)?.toInt() ?? 0;
    final name = item['name'] as String? ?? '';
    final avatar = resolveMediaUrl(item['avatar'] as String?);
    final total = (item['total'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: id > 0 ? () => context.push('/user-profile/$id') : null,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty ? const Icon(Icons.person, size: 24) : null,
            ),
            const SizedBox(height: 4),
            Text(_formatCount(total),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _GiftTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _GiftTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final img = resolveMediaUrl(item['img'] as String?);
    final qty = (item['num'] as num?)?.toInt() ?? 0;

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: img.isNotEmpty
                ? Image.network(img, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.card_giftcard, size: 20))
                : const Icon(Icons.card_giftcard, size: 20),
          ),
          const SizedBox(height: 2),
          Text('x$qty', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
