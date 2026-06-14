import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../bloc/room_management_bloc.dart';
import 'ban_duration_dialog.dart';
import 'room_strings.dart';

Future<void> showUserProfileSheet(
  BuildContext context, {
  required UTDRoomController controller,
  required SeatState seat,
  required String localUserId,
  required bool isOwner,
  required int roomId,
  required RoomManagementBloc roomManagementBloc,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider.value(
      value: roomManagementBloc,
      child: _UserProfileBody(
        controller: controller,
        seat: seat,
        localUserId: localUserId,
        isOwner: isOwner,
        roomId: roomId,
      ),
    ),
  );
}

class _UserProfileBody extends StatelessWidget {
  final UTDRoomController controller;
  final SeatState seat;
  final String localUserId;
  final bool isOwner;
  final int roomId;

  const _UserProfileBody({
    required this.controller,
    required this.seat,
    required this.localUserId,
    required this.isOwner,
    required this.roomId,
  });

  String get _userId => seat.occupantUserId ?? '';
  String get _userName => seat.attributes['name'] ?? '';
  String? get _avatar => seat.attributes['avatar'];
  bool get _isMyProfile => _userId == localUserId;

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);
    final isAdmin = controller.isHostOrAdmin;
    final targetRole = controller.getParticipantRole(_userId);
    final isTargetAdmin = targetRole == 'admin' || targetRole == 'host';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _Avatar(url: _avatar),
          const SizedBox(height: 12),
          Text(
            _userName.isNotEmpty ? _userName : s.user,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: $_userId',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (isTargetAdmin && !_isMyProfile)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  targetRole == 'host' ? s.host : s.admin,
                  style: const TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 20),
          if (_isMyProfile) ...[
            _ActionButton(
              icon: Icons.exit_to_app,
              label: s.leaveSeat,
              onTap: () async {
                Navigator.of(context).pop();
                await controller.seatController.leaveSeat(localUserId);
              },
            ),
          ] else ...[
            if (isAdmin && seat.isOccupied && !isTargetAdmin) ...[
              ValueListenableBuilder<Set<String>>(
                valueListenable: controller.mutedParticipants,
                builder: (context, muted, _) {
                  final isMuted = muted.contains(_userId);
                  return _ActionButton(
                    icon: isMuted ? Icons.mic : Icons.mic_off,
                    label: isMuted ? s.unmute : s.mute,
                    onTap: () async {
                      final seatIndex = controller.seatController
                          .getSeatIndexByUserId(_userId);
                      if (seatIndex < 0) return;
                      final identity = controller.localIdentity ?? localUserId;
                      bool ok;
                      if (isMuted) {
                        ok = await controller.seatController.unmuteSeat(
                          seatIndex,
                          identity: identity,
                        );
                      } else {
                        ok = await controller.seatController.muteSeat(
                          seatIndex,
                          identity: identity,
                        );
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? (isMuted ? s.userUnmuted : s.userMuted)
                                  : s.failed,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              _ActionButton(
                icon: Icons.person_remove,
                label: s.kickFromSeat,
                color: Colors.orange,
                onTap: () async {
                  Navigator.of(context).pop();
                  final seatIndex = controller.seatController
                      .getSeatIndexByUserId(_userId);
                  if (seatIndex < 0) return;
                  final identity = controller.localIdentity ?? localUserId;
                  await controller.seatController.kickFromSeat(
                    seatIndex,
                    identity: identity,
                  );
                },
              ),
            ],
            if (isAdmin && !isTargetAdmin)
              _ActionButton(
                icon: Icons.block,
                label: s.ban,
                color: Colors.red,
                onTap: () => _handleBan(context),
              ),
            if (isOwner && !_isMyProfile)
              _ActionButton(
                icon: isTargetAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                label: isTargetAdmin ? s.removeAdmin : s.makeAdmin,
                color: isTargetAdmin ? Colors.orange : Colors.green,
                onTap: () => _handleRoleChange(context, isTargetAdmin),
              ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _handleBan(BuildContext context) async {
    final result = await showBanDurationDialog(context);
    if (result == null || !context.mounted) return;

    final durationSeconds = result == -1 ? null : result;
    final bloc = context.read<RoomManagementBloc>();

    // 1) Backend ban — persists in database
    final userId = int.tryParse(_userId);
    if (userId != null) {
      bloc.add(
        BanUserEvent(
          roomId: roomId,
          userId: userId,
          durationSeconds: durationSeconds,
        ),
      );
    }

    // 2) Kit ban — kicks from LiveKit session immediately
    final ok = await controller.banUser(
      _userId,
      durationSeconds: durationSeconds,
    );

    if (context.mounted) {
      final s = RoomStrings.of(context);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ok ? s.userBanned : s.banFailed)));
    }
  }

  Future<void> _handleRoleChange(
    BuildContext context,
    bool isCurrentlyAdmin,
  ) async {
    final role = isCurrentlyAdmin ? 'audience' : 'admin';
    final bloc = context.read<RoomManagementBloc>();
    try {
      await controller.changeRole(targetIdentity: _userId, role: role);
      final userId = int.tryParse(_userId);
      if (userId != null) {
        if (isCurrentlyAdmin) {
          bloc.add(RemoveAdminEvent(roomId: roomId, userId: userId));
        } else {
          bloc.add(AddAdminEvent(roomId: roomId, userId: userId));
        }
      }
      if (context.mounted) {
        final s = RoomStrings.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyAdmin ? s.adminRemoved : s.adminAdded),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        final s = RoomStrings.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.roleChangeFailed)));
      }
    }
  }
}

class _Avatar extends StatelessWidget {
  final String? url;

  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey.shade700,
        child: const Icon(Icons.person, size: 40, color: Colors.white70),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade700,
          child: const Icon(Icons.person, size: 40, color: Colors.white70),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white.withValues(alpha: 0.06),
        leading: Icon(icon, color: c, size: 22),
        title: Text(label, style: TextStyle(color: c, fontSize: 15)),
        onTap: onTap,
      ),
    );
  }
}
