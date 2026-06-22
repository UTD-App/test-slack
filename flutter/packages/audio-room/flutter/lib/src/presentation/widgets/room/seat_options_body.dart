import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../bloc/admin_bloc.dart';
import '../../bloc/blacklist_bloc.dart';
import 'invite_to_mic_sheet.dart';
import 'room_strings.dart';
import 'seat_option_tile.dart';
import 'user_profile_sheet.dart';

class SeatOptionsBody extends StatelessWidget {
  final UTDRoomController controller;
  final int seatIndex;
  final SeatState seat;
  final String localUserId;
  final bool isOwner;
  final bool isSeatEmpty;
  final bool isOwnSeat;
  final bool isAdmin;
  final bool isLocked;
  final int roomId;
  final AdminBloc adminBloc;
  final BlacklistBloc blacklistBloc;

  const SeatOptionsBody({
    super.key,
    required this.controller,
    required this.seatIndex,
    required this.seat,
    required this.localUserId,
    required this.isOwner,
    required this.isSeatEmpty,
    required this.isOwnSeat,
    required this.isAdmin,
    required this.isLocked,
    required this.roomId,
    required this.adminBloc,
    required this.blacklistBloc,
  });

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);
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
          const SizedBox(height: 8),
          Text(
            s.seat(seatIndex),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // --- Empty seat options ---
          if (isSeatEmpty) ...[
            // Admin: lock/unlock
            if (isAdmin)
              SeatOptionTile(
                icon: isLocked ? Icons.lock_open : Icons.lock,
                label: isLocked ? s.unlockSeat : s.lockSeat,
                onTap: () async {
                  Navigator.of(context).pop();
                  final identity =
                      controller.localIdentity ?? localUserId;
                  if (isLocked) {
                    await controller.seatController
                        .unlockSeat(seatIndex, identity: identity);
                  } else {
                    await controller.seatController
                        .lockSeat(seatIndex, identity: identity);
                  }
                },
              ),

            // Admin: invite to mic
            if (isAdmin)
              SeatOptionTile(
                icon: Icons.person_add,
                label: s.inviteToMic,
                onTap: () {
                  Navigator.of(context).pop();
                  showInviteToMicSheet(
                    context,
                    controller: controller,
                    seatIndex: seatIndex,
                  );
                },
              ),

            // Take seat / switch seat
            if (!isLocked || isAdmin)
              SeatOptionTile(
                icon: Icons.event_seat,
                label: controller.localSeatIndex >= 0
                    ? s.switchSeat
                    : s.takeSeat,
                onTap: () => _takeSeat(context),
              ),
          ],

          // --- Own seat options ---
          if (isOwnSeat) ...[
            SeatOptionTile(
                icon: Icons.exit_to_app,
                label: s.leaveSeat,
                onTap: () async {
                  Navigator.of(context).pop();
                  await controller.seatController
                      .leaveSeat(localUserId);
                },
              ),
            SeatOptionTile(
              icon: Icons.person,
              label: s.myProfile,
              onTap: () {
                Navigator.of(context).pop();
                showUserProfileSheet(
                  context,
                  controller: controller,
                  seat: seat,
                  localUserId: localUserId,
                  isOwner: isOwner,
                  roomId: roomId,
                  adminBloc: adminBloc,
                  blacklistBloc: blacklistBloc,
                );
              },
            ),
          ],

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                s.cancel,
                style: const TextStyle(color: Colors.white54, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _takeSeat(BuildContext context) async {
    Navigator.of(context).pop();
    final seatCtrl = controller.seatController;
    final currentSeat = seatCtrl.getSeatIndexByUserId(localUserId);

    bool ok;
    if (currentSeat >= 0) {
      ok = await seatCtrl.moveSeat(localUserId, seatIndex);
    } else {
      ok = await seatCtrl.takeSeat(seatIndex, localUserId);
    }

    if (!ok && context.mounted) {
      final s = RoomStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.couldNotTakeSeat)),
      );
    }
  }
}
