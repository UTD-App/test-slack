import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'notification_data_extension.dart';

/// Bell icon for the bottom-nav tab, with a live unread badge driven by
/// [NotificationDataExtension]. Used as both the active and inactive tab icon.
class NotificationBell extends StatelessWidget {
  final bool filled;

  const NotificationBell({super.key, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final ext = context.watch<NotificationDataExtension>();
    final count = ext.unreadCount;
    final icon = Icon(filled ? Icons.notifications : Icons.notifications_none);

    if (count <= 0) return icon;

    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}
