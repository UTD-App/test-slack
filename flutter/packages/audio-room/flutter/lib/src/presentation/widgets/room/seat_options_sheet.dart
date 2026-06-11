import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../bloc/room_management_bloc.dart';
import 'invite_to_mic_sheet.dart';
import 'room_strings.dart';
import 'user_profile_sheet.dart';

void handleSeatTap(
  BuildContext context, {
  required UTDRoomController controller,
  required int seatIndex,
  required SeatState seat,
  required String localUserId,
  required bool isOwner,
  required int roomId,
}) {
  final seatCtrl = controller.seatController;
  final isAdmin = controller.isHostOrAdmin;
  final isLocked = seatCtrl.isSeatLocked(seatIndex);
  final isSeatEmpty = seat.isEmpty || seat.occupantUserId == null;
  final isOwnSeat =
      !isSeatEmpty && seat.occupantUserId == localUserId;

  final s = RoomStrings.of(context);

  // Seat 0 (owner seat) + non-owner → always locked
  if (seatIndex == 0 && !isOwner && isSeatEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.seatReservedForOwner)),
    );
    return;
  }

  // Locked seat + non-admin → snackbar only
  if (isLocked && !isAdmin && isSeatEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.seatLocked)),
    );
    return;
  }

  // Occupied seat by someone else → show profile
  if (!isSeatEmpty && !isOwnSeat) {
    showUserProfileSheet(
      context,
      controller: controller,
      seat: seat,
      localUserId: localUserId,
      isOwner: isOwner,
      roomId: roomId,
      roomManagementBloc: context.read<RoomManagementBloc>(),
    );
    return;
  }

  // Own seat or empty seat → show options sheet
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SeatOptionsBody(
      controller: controller,
      seatIndex: seatIndex,
      seat: seat,
      localUserId: localUserId,
      isOwner: isOwner,
      isSeatEmpty: isSeatEmpty,
      isOwnSeat: isOwnSeat,
      isAdmin: isAdmin,
      isLocked: isLocked,
      roomId: roomId,
      roomManagementBloc: context.read<RoomManagementBloc>(),
    ),
  );
}

class _SeatOptionsBody extends StatelessWidget {
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
  final RoomManagementBloc roomManagementBloc;

  const _SeatOptionsBody({
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
    required this.roomManagementBloc,
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
              _OptionTile(
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
              _OptionTile(
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
              _OptionTile(
                icon: Icons.event_seat,
                label: controller.localSeatIndex >= 0
                    ? s.switchSeat
                    : s.takeSeat,
                onTap: () => _takeSeat(context),
              ),
          ],

          // --- Own seat options ---
          if (isOwnSeat) ...[
            // Host should not leave seat 0 accidentally
            if (seatIndex != 0 || !isOwner)
              _OptionTile(
                icon: Icons.exit_to_app,
                label: s.leaveSeat,
                onTap: () async {
                  Navigator.of(context).pop();
                  await controller.seatController
                      .leaveSeat(localUserId);
                },
              ),
            _OptionTile(
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
                  roomManagementBloc: roomManagementBloc,
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.white.withValues(alpha: 0.06),
        leading: Icon(icon, color: Colors.white, size: 22),
        title:
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        onTap: onTap,
      ),
    );
  }
}
