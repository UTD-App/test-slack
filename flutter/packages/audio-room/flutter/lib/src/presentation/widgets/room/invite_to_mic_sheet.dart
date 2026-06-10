import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'room_strings.dart';

Future<void> showInviteToMicSheet(
  BuildContext context, {
  required UTDRoomController controller,
  required int seatIndex,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _InviteToMicBody(
      controller: controller,
      seatIndex: seatIndex,
    ),
  );
}

class _InviteToMicBody extends StatefulWidget {
  final UTDRoomController controller;
  final int seatIndex;

  const _InviteToMicBody({
    required this.controller,
    required this.seatIndex,
  });

  @override
  State<_InviteToMicBody> createState() => _InviteToMicBodyState();
}

class _InviteToMicBodyState extends State<_InviteToMicBody> {
  final _invitedIds = <String>{};

  List<UTDParticipant> get _audienceMembers {
    final seatCtrl = widget.controller.seatController;
    final localId = widget.controller.localIdentity;

    return widget.controller.participants
        .where((p) => !seatCtrl.isUserOnSeat(p.id) && p.id != localId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);
    final users = _audienceMembers;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            const SizedBox(height: 12),
            Text(
              s.inviteToSeat(widget.seatIndex),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  s.noAudienceMembers,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final user = users[i];
                    return _UserRow(
                      user: user,
                      invited: _invitedIds.contains(user.id),
                      onInvite: () => _invite(user),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _invite(UTDParticipant user) async {
    final result = await widget.controller.inviteToSpeak(
      user.id,
      seatIndex: widget.seatIndex,
    );

    if (!mounted) return;

    final s = RoomStrings.of(context);
    if (result != null) {
      setState(() => _invitedIds.add(user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.invitationSentTo(user.name))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.invitationFailed)),
      );
    }
  }
}

class _UserRow extends StatelessWidget {
  final UTDParticipant user;
  final bool invited;
  final VoidCallback onInvite;

  const _UserRow({
    required this.user,
    required this.invited,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);
    final avatar = user.attributes['avatar'];

    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Colors.white.withValues(alpha: 0.06),
      leading: ClipOval(
        child: avatar != null && avatar.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatar,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    _defaultAvatar(),
              )
            : _defaultAvatar(),
      ),
      title: Text(
        user.name.isNotEmpty ? user.name : '${s.user} ${user.id}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 75,
        height: 30,
        child: ElevatedButton(
          onPressed: invited ? null : onInvite,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                invited ? Colors.grey.shade700 : const Color(0xFF4CAF50),
            disabledBackgroundColor: Colors.grey.shade700,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            invited ? s.sent : s.invite,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade600,
      ),
      child: const Icon(Icons.person, color: Colors.white70, size: 20),
    );
  }
}
