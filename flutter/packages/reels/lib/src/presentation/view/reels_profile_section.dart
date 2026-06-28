import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/profile/profile_view_arguments.dart';

import '../../../core/reels_routes.dart';
import '../../../core/reels_strings.dart';

/// Profile section contributed by the Reels package: the user's reels count.
/// Reads the loaded `sections.reels` from ProfileViewArguments. Tapping it opens
/// that user's reels grid (`/reels/user/{id}`).
class ReelsProfileSection extends StatelessWidget {
  const ReelsProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    ProfileViewArguments? args;
    try {
      args = context.read<ProfileViewArguments>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    final count = (args.section('reels')['count'] as num?)?.toInt() ?? 0;
    final targetUserId = args.userId;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.smart_display_outlined),
        title: Text(context.tr(ReelsStrings.title),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
        onTap: () => context.push(ReelsRoutes.userReelsPath(targetUserId)),
      ),
    );
  }
}
