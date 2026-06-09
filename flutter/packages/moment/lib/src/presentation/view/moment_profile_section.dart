import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/profile/profile_view_arguments.dart';

import '../../../core/moment_strings.dart';

/// Profile section contributed by the Moment package: the user's moments count.
/// Reads the loaded `sections.moments` from ProfileViewArguments.
class MomentProfileSection extends StatelessWidget {
  const MomentProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    ProfileViewArguments? args;
    try {
      args = context.read<ProfileViewArguments>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    final count = (args.section('moments')['count'] as num?)?.toInt() ?? 0;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.dynamic_feed_outlined),
        title: Text(context.tr(MomentStrings.title),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        trailing: Text('$count',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
      ),
    );
  }
}
