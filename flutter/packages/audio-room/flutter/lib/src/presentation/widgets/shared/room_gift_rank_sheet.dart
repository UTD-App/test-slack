import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:utd_app/config/app_config.dart';
import 'package:utd_app/network/client/api_client.dart';

import '../../../gifts/gift_event_bus.dart';

class RoomGiftRankSheet extends StatefulWidget {
  final int roomId;

  const RoomGiftRankSheet({super.key, required this.roomId});

  static Future<void> show(BuildContext context, {required int roomId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RoomGiftRankSheet(roomId: roomId),
    );
  }

  @override
  State<RoomGiftRankSheet> createState() => _RoomGiftRankSheetState();
}

class _RoomGiftRankSheetState extends State<RoomGiftRankSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StreamSubscription<GiftDisplayEvent>? _giftSub;

  List<_UserRankEntry> _senders = [];
  List<_UserRankEntry> _receivers = [];
  List<_GiftRankEntry> _gifts = [];

  bool _sendersLoading = true;
  bool _receiversLoading = true;
  bool _giftsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
    _giftSub = GiftEventBus.instance.stream.listen((_) => _fetchAll());
  }

  @override
  void dispose() {
    _giftSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    final dio = ApiClient.instance.dio;
    final base = '/gifts/context/room/${widget.roomId}';

    await Future.wait([
      dio.get('$base/gifters').then((r) {
        debugPrint('🎁 gifters raw: ${r.data}');
        final list = _extractList(r.data);
        if (mounted) {
          setState(() {
            _senders = list.map((e) => _UserRankEntry.fromMap(e)).toList();
            _sendersLoading = false;
          });
          for (final s in _senders) {
            debugPrint('🎁 sender: ${s.name} avatar: ${s.avatarUrl}');
          }
        }
      }).catchError((e) {
        debugPrint('🎁 gifters error: $e');
        if (mounted) setState(() => _sendersLoading = false);
      }),
      dio.get('$base/receivers').then((r) {
        final list = _extractList(r.data);
        if (mounted) {
          setState(() {
            _receivers = list.map((e) => _UserRankEntry.fromMap(e)).toList();
            _receiversLoading = false;
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _receiversLoading = false);
      }),
      dio.get(base).then((r) {
        final list = _extractList(r.data);
        if (mounted) {
          setState(() {
            _gifts = list.map((e) => _GiftRankEntry.fromMap(e)).toList();
            _giftsLoading = false;
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _giftsLoading = false);
      }),
    ]);

  }

  static List<Map<String, dynamic>> _extractList(dynamic data) {
    final raw = (data is Map ? data['data'] : data) as List? ?? [];
    return raw.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  SizedBox(width: 8.w),
                  Text('الترتيب', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'المرسلين'),
                Tab(text: 'المستقبلين'),
                Tab(text: 'الهدايا'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUserList(_senders, _sendersLoading),
                  _buildUserList(_receivers, _receiversLoading),
                  _buildGiftList(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserList(List<_UserRankEntry> users, bool loading) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return const Center(child: Text('لا توجد بيانات'));

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _UserRankTile(user: user, rank: index + 1);
      },
    );
  }

  Widget _buildGiftList() {
    if (_giftsLoading) return const Center(child: CircularProgressIndicator());
    if (_gifts.isEmpty) return const Center(child: Text('لا توجد هدايا'));

    return ListView.builder(
      itemCount: _gifts.length,
      itemBuilder: (context, index) {
        final gift = _gifts[index];
        return _GiftRankTile(gift: gift, rank: index + 1);
      },
    );
  }
}

// ─── Data classes ───

class _UserRankEntry {
  final int id;
  final String name;
  final String avatarUrl;
  final int giftCount;

  const _UserRankEntry({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.giftCount,
  });

  factory _UserRankEntry.fromMap(Map<String, dynamic> map) {
    final user = map['user'] as Map<String, dynamic>? ?? {};
    final rawAvatar = user['avatar']?.toString() ?? '';
    final name = user['name']?.toString() ?? '';
    final resolved = _resolveAvatar(rawAvatar);
    return _UserRankEntry(
      id: (user['id'] as num?)?.toInt() ?? 0,
      name: name,
      avatarUrl: resolved.isNotEmpty
          ? resolved
          : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&size=128',
      giftCount: (map['num'] as num?)?.toInt() ?? 0,
    );
  }
}

class _GiftRankEntry {
  final int giftId;
  final String name;
  final String img;
  final int count;

  const _GiftRankEntry({
    required this.giftId,
    required this.name,
    required this.img,
    required this.count,
  });

  factory _GiftRankEntry.fromMap(Map<String, dynamic> map) {
    return _GiftRankEntry(
      giftId: (map['gift_id'] as num?)?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      img: _resolveAvatar(map['img']?.toString() ?? ''),
      count: (map['num'] as num?)?.toInt() ?? 0,
    );
  }
}

String _resolveAvatar(String path) {
  if (path.isEmpty || path.startsWith('http')) return path;
  final clean = path.startsWith('/') ? path.substring(1) : path;
  return '${appConfig.domainUrl}/storage/$clean';
}

// ─── Tiles ───

class _UserRankTile extends StatelessWidget {
  final _UserRankEntry user;
  final int rank;

  const _UserRankTile({required this.user, required this.rank});

  Color? get _rankColor => switch (rank) {
        1 => const Color(0xFFFFD700),
        2 => const Color(0xFFC0C0C0),
        3 => const Color(0xFFCD7F32),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _rankColor;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color ?? theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: NetworkImage(user.avatarUrl),
            onBackgroundImageError: (_, __) {},
          ),
        ],
      ),
      title: Text(
        user.name,
        style: TextStyle(
          fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_giftcard, size: 16, color: color ?? Colors.grey),
          const SizedBox(width: 4),
          Text(
            _formatCount(user.giftCount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftRankTile extends StatelessWidget {
  final _GiftRankEntry gift;
  final int rank;

  const _GiftRankTile({required this.gift, required this.rank});

  Color? get _rankColor => switch (rank) {
        1 => const Color(0xFFFFD700),
        2 => const Color(0xFFC0C0C0),
        3 => const Color(0xFFCD7F32),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _rankColor;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color ?? theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: gift.img.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: gift.img,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.card_giftcard, size: 20),
                  )
                : const Icon(Icons.card_giftcard, size: 20),
          ),
        ],
      ),
      title: Text(
        gift.name,
        style: TextStyle(
          fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
      trailing: Text(
        '×${_formatCount(gift.count)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color ?? theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
