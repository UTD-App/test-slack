import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../audio_room_feature.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/blacklist_bloc.dart';
import 'ban_duration_dialog.dart';
import 'mute_only_button.dart';
import 'profile_action_button.dart';
import 'profile_header.dart';
import 'room_strings.dart';

class UserProfileBody extends StatelessWidget {
  final UTDRoomController controller;
  final SeatState seat;
  final String localUserId;
  final bool isOwner;
  final int roomId;

  const UserProfileBody({
    super.key,
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
  bool get _isOnSeat =>
      controller.seatController.getSeatIndexByUserId(_userId) >= 0;

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
          ProfileHeader(
            avatarUrl: _avatar,
            userName: _userName.isNotEmpty ? _userName : s.user,
            userId: _userId,
            role: isTargetAdmin && !_isMyProfile
                ? (targetRole == 'host' ? s.host : s.admin)
                : null,
          ),
          const SizedBox(height: 20),
          if (_isMyProfile) ...[
            if (_isOnSeat) ...[
              MuteOnlyButton(
                controller: controller,
                userId: _userId,
                localUserId: localUserId,
              ),
              ProfileActionButton(
                icon: Icons.exit_to_app,
                label: s.leaveSeat,
                onTap: () async {
                  Navigator.of(context).pop();
                  await controller.seatController.leaveSeat(localUserId);
                },
              ),
            ],
          ] else ...[
            if (isAdmin && _isOnSeat && !isTargetAdmin) ...[
              MuteOnlyButton(
                controller: controller,
                userId: _userId,
                localUserId: localUserId,
              ),
              ProfileActionButton(
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
            if (isAdmin && !_isOnSeat && !isTargetAdmin)
              ProfileActionButton(
                icon: Icons.person_add,
                label: s.inviteToMic,
                color: Colors.green,
                onTap: () => _handleInvite(context),
              ),
            if (isAdmin && !isTargetAdmin) ...[
              ValueListenableBuilder<Set<String>>(
                valueListenable:
                    AudioRoomFeature.instance!.commentBannedUsers,
                builder: (context, banned, _) {
                  final isBanned = banned.contains(_userId);
                  return ProfileActionButton(
                    icon: isBanned
                        ? Icons.comment
                        : Icons.comments_disabled,
                    label: isBanned ? s.unbanComments : s.banComments,
                    color: isBanned ? Colors.green : Colors.orange,
                    onTap: () => _handleCommentBan(context, !isBanned),
                  );
                },
              ),
              ProfileActionButton(
                icon: Icons.block,
                label: s.ban,
                color: Colors.red,
                onTap: () => _handleBan(context),
              ),
            ],
            if (isOwner && !_isMyProfile)
              ProfileActionButton(
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

  Future<void> _handleInvite(BuildContext context) async {
    Navigator.of(context).pop();
    final s = RoomStrings.of(context);
    final result = await controller.inviteToSpeak(_userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result != null
                ? s.invitationSentTo(_userName)
                : s.invitationFailed,
          ),
        ),
      );
    }
  }

  void _handleCommentBan(BuildContext context, bool ban) {
    final feature = AudioRoomFeature.instance;
    if (feature == null) return;

    final updated = Set<String>.from(feature.commentBannedUsers.value);
    if (ban) {
      updated.add(_userId);
    } else {
      updated.remove(_userId);
    }
    feature.commentBannedUsers.value = updated;

    controller.sendRoomMessage({
      'type': 'commentBan',
      'data': {'user_id': _userId, 'banned': ban},
    });

    final s = RoomStrings.of(context);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ban ? s.commentsBannedSuccess : s.commentsUnbannedSuccess),
      ),
    );
  }

  Future<void> _handleBan(BuildContext context) async {
    final result = await showBanDurationDialog(context);
    if (result == null || !context.mounted) return;

    final durationSeconds = result == -1 ? null : result;
    final userId = int.tryParse(_userId);
    if (userId != null) {
      context.read<BlacklistBloc>().add(
        BanUserEvent(
          roomId: roomId,
          userId: userId,
          durationSeconds: durationSeconds,
        ),
      );
    }

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
    try {
      await controller.changeRole(targetIdentity: _userId, role: role);
      final userId = int.tryParse(_userId);
      if (userId != null) {
        final adminBloc = context.read<AdminBloc>();
        if (isCurrentlyAdmin) {
          adminBloc.add(RemoveAdminEvent(roomId: roomId, userId: userId));
        } else {
          adminBloc.add(AddAdminEvent(roomId: roomId, userId: userId));
        }
      }
      final promoterData = CacheManager.getUserData();
      controller.sendRoomMessage({
        'type': 'roleChange',
        'data': {
          'user_id': _userId,
          'role': role,
          'user_name': _userName,
          'promoter_name': promoterData?['name']?.toString() ?? '',
        },
      });
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
