import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../domain/charisma_model.dart';
import '../bloc/charisma_bloc.dart';
import '../charisma_strings.dart';

class CharismaLeaderboardSheet extends StatelessWidget {
  final CharismaBloc bloc;
  final UTDRoomController? controller;

  const CharismaLeaderboardSheet({
    super.key,
    required this.bloc,
    this.controller,
  });

  static void show(
      BuildContext context, CharismaBloc bloc, UTDRoomController? controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) =>
            CharismaLeaderboardSheet(bloc: bloc, controller: controller),
      ),
    );
  }

  Map<String, _UserInfo> _buildUserInfoMap() {
    if (controller == null) return {};
    final map = <String, _UserInfo>{};

    for (final p in controller!.participants) {
      map[p.id] = _UserInfo(
        name: p.name,
        avatar: p.attributes['avatar'],
      );
    }

    for (final seat in controller!.seatController.seats.value) {
      if (seat.occupantUserId != null && !map.containsKey(seat.occupantUserId)) {
        map[seat.occupantUserId!] = _UserInfo(
          name: seat.attributes['name'],
          avatar: seat.attributes['avatar'],
        );
      }
    }

    return map;
  }

  List<CharismaModel> _mergeWithSeats(List<CharismaModel> data) {
    if (controller == null) return data;

    final seats = controller!.seatController.seats.value;
    final merged = <String, CharismaModel>{};

    for (final entry in data) {
      merged[entry.userId.toString()] = entry;
    }

    for (final seat in seats) {
      if (seat.occupantUserId != null &&
          !merged.containsKey(seat.occupantUserId)) {
        merged[seat.occupantUserId!] = CharismaModel(
          userId: int.tryParse(seat.occupantUserId!) ?? 0,
          total: '0',
          position: 0,
        );
      }
    }

    final list = merged.values.toList();
    list.sort((a, b) {
      final aTotal = int.tryParse(a.total) ?? 0;
      final bTotal = int.tryParse(b.total) ?? 0;
      return bTotal.compareTo(aTotal);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final s = CharismaStrings.of(context);

    return BlocBuilder<CharismaBloc, CharismaState>(
      bloc: bloc,
      builder: (context, state) {
        final data = _mergeWithSeats(state.data ?? []);

        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.pinkAccent, size: 20),
                const SizedBox(width: 6),
                Text(
                  s.charismaRanking,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    s.noData,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              )
            else
              Expanded(
                child: Builder(builder: (context) {
                  final userInfoMap = _buildUserInfoMap();
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, index) {
                      final entry = data[index];
                      final info = userInfoMap[entry.userId.toString()];
                      return _LeaderboardRow(
                        entry: entry,
                        rank: index + 1,
                        userName: info?.name,
                        avatarUrl: info?.avatar,
                      );
                    },
                  );
                }),
              ),
          ],
        );
      },
    );
  }
}

class _UserInfo {
  final String? name;
  final String? avatar;

  const _UserInfo({this.name, this.avatar});
}

class _LeaderboardRow extends StatelessWidget {
  final CharismaModel entry;
  final int rank;
  final String? userName;
  final String? avatarUrl;

  const _LeaderboardRow({
    required this.entry,
    required this.rank,
    this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final s = CharismaStrings.of(context);
    final isTop3 = rank <= 3;
    final rankColors = [Colors.amber, Colors.grey.shade400, Colors.orange];
    final displayName = (userName != null && userName!.isNotEmpty)
        ? userName!
        : s.user(entry.userId);
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: isTop3
                ? Icon(Icons.emoji_events,
                    color: rankColors[rank - 1], size: 22)
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.purple.withValues(alpha: 0.3),
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
            child: hasAvatar
                ? null
                : const Icon(Icons.person, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                color: isTop3 ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isTop3 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: Colors.pinkAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                entry.total,
                style: TextStyle(
                  color: isTop3 ? Colors.pinkAccent : Colors.white54,
                  fontSize: 14,
                  fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
