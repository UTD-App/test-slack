import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'invite_user_row.dart';
import 'room_strings.dart';

class InviteToMicBody extends StatefulWidget {
  final UTDRoomController controller;
  final int seatIndex;

  const InviteToMicBody({
    super.key,
    required this.controller,
    required this.seatIndex,
  });

  @override
  State<InviteToMicBody> createState() => _InviteToMicBodyState();
}

class _InviteToMicBodyState extends State<InviteToMicBody> {
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
                    return InviteUserRow(
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
