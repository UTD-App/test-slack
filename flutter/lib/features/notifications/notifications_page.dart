import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';

import 'notification_api_service.dart';
import 'notification_data_extension.dart';
import 'notification_models.dart';

/// The in-app notification feed. Shown as the Notifications tab body (and the
/// /notifications route). Pull-to-refresh, tap-to-read, mark-all-read.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationApiService _api = NotificationApiService();

  List<NotificationItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _api.fetchFeed();
    if (!mounted) return;

    result.when(
      success: (items) {
        setState(() {
          _items = items;
          _loading = false;
        });
        _syncBadge();
      },
      failure: (message, _) {
        setState(() {
          _error = message;
          _loading = false;
        });
      },
    );
  }

  void _syncBadge() {
    final unread = _items.where((n) => !n.isRead).length;
    context.read<NotificationDataExtension>().setUnread(unread);
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) return;
    setState(() {
      _items = _items.map((n) => n.id == item.id ? n.copyWith(isRead: true) : n).toList();
    });
    context.read<NotificationDataExtension>().decrement();
    await _api.markRead(item.id);
  }

  Future<void> _markAllRead() async {
    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    });
    context.read<NotificationDataExtension>().setUnread(0);
    await _api.markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
        title: Text(
          context.tr('notifications.title'),
          style: const TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                context.tr('notifications.mark_all_read'),
                style: const TextStyle(color: ColorManager.lumiaAccentLight),
              ),
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: ColorManager.lumiaAccent,
            backgroundColor: ColorManager.lumiaCardBg,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ColorManager.lumiaAccentLight),
      );
    }

    if (_error != null) {
      return _CenteredScroll(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: ColorManager.walletRed),
            const SizedBox(height: 12),
            Text(
              context.tr('notifications.error'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColorManager.lumiaTextPrimary),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ColorManager.lumiaAccent,
              ),
              onPressed: _load,
              child: Text(context.tr('notifications.retry')),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return _CenteredScroll(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: ColorManager.lumiaTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('notifications.empty'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorManager.lumiaTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('notifications.empty_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColorManager.lumiaTextSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.5,
        color: ColorManager.frostedBorder,
      ),
      itemBuilder: (context, i) => _NotificationTile(
        item: _items[i],
        onTap: () => _markRead(_items[i]),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatar = item.actor?.avatar;

    return ListTile(
      onTap: onTap,
      tileColor: item.isRead
          ? Colors.transparent
          : ColorManager.lumiaAccent.withValues(alpha: 0.12),
      leading: CircleAvatar(
        backgroundColor: ColorManager.lumiaCardBg,
        backgroundImage: (avatar != null && avatar.startsWith('http')) ? NetworkImage(avatar) : null,
        child: (avatar == null || !avatar.startsWith('http'))
            ? const Icon(Icons.notifications, color: ColorManager.lumiaAccentLight)
            : null,
      ),
      title: item.title.isNotEmpty
          ? Text(item.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColorManager.lumiaTextPrimary))
          : Text(item.body,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: ColorManager.lumiaTextPrimary)),
      subtitle: item.title.isNotEmpty
          ? Text(item.body,
              style: const TextStyle(color: ColorManager.lumiaTextSecondary))
          : null,
      trailing: Text(
        _timeAgo(item.createdAt),
        style: const TextStyle(fontSize: 11, color: ColorManager.lumiaTextSecondary),
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _CenteredScroll extends StatelessWidget {
  final Widget child;
  const _CenteredScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(padding: const EdgeInsets.all(32), child: child),
          ),
        ),
      ),
    );
  }
}
