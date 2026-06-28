import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'package:audio_room/src/audio_room_strings.dart';
import '../../../../audio_room_feature.dart';
import '../../../bloc/admin/admin_bloc.dart';
import '../../../bloc/blacklist/blacklist_bloc.dart';
import '../admin/ban_duration_dialog.dart';
import '../controls/mute_only_button.dart';
import 'profile_action_button.dart';
import 'profile_header.dart';

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
    final isAdmin = controller.isHostOrAdmin;
    final targetRole = controller.getParticipantRole(_userId);
    final isTargetAdmin = targetRole == 'admin' || targetRole == 'host';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          ProfileHeader(
            avatarUrl: _avatar,
            userName: _userName.isNotEmpty ? _userName : context.tr(AudioRoomKeys.user),
            userId: _userId,
            role: isTargetAdmin && !_isMyProfile
                ? (targetRole == 'host' ? context.tr(AudioRoomKeys.host) : context.tr(AudioRoomKeys.admin))
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
                label: context.tr(AudioRoomKeys.leaveSeat),
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
                label: context.tr(AudioRoomKeys.kickFromSeat),
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
                label: context.tr(AudioRoomKeys.inviteToMic),
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
                    label: isBanned ? context.tr(AudioRoomKeys.unbanComments) : context.tr(AudioRoomKeys.banComments),
                    color: isBanned ? Colors.green : Colors.orange,
                    onTap: () => _handleCommentBan(context, !isBanned),
                  );
                },
              ),
              ProfileActionButton(
                icon: Icons.block,
                label: context.tr(AudioRoomKeys.ban),
                color: Colors.red,
                onTap: () => _handleBan(context),
              ),
            ],
            if (isOwner && !_isMyProfile)
              ProfileActionButton(
                icon: isTargetAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                label: isTargetAdmin ? context.tr(AudioRoomKeys.removeAdmin) : context.tr(AudioRoomKeys.makeAdmin),
                color: isTargetAdmin ? Colors.orange : Colors.green,
                onTap: () => _handleRoleChange(context, isTargetAdmin),
              ),
          ],
          const SizedBox(height: 12),
        ],
        ),
      ),
    );
  }

  Future<void> _handleInvite(BuildContext context) async {
    Navigator.of(context).pop();
    final result = await controller.inviteToSpeak(_userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result != null
                ? context.trArgs(AudioRoomKeys.invitationSentTo, {'name': _userName})
                : context.tr(AudioRoomKeys.invitationFailed),
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

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ban ? context.tr(AudioRoomKeys.commentsBannedSuccess) : context.tr(AudioRoomKeys.commentsUnbannedSuccess)),
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ok ? context.tr(AudioRoomKeys.userBanned) : context.tr(AudioRoomKeys.banFailed))));
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyAdmin ? context.tr(AudioRoomKeys.adminRemoved) : context.tr(AudioRoomKeys.adminAdded)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr(AudioRoomKeys.roleChangeFailed))));
      }
    }
  }
}
