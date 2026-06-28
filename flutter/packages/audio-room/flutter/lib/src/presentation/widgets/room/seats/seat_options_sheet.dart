import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'package:utd_app/localization/localization.dart';

import '../../../../audio_room_strings.dart';
import '../../../bloc/admin/admin_bloc.dart';
import '../../../bloc/blacklist/blacklist_bloc.dart';
import 'seat_options_body.dart';
import '../profile/user_profile_sheet.dart';

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

  // Seat 0 (owner seat) + non-owner → always locked
  if (seatIndex == 0 && !isOwner && isSeatEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(AudioRoomKeys.seatReservedForOwner))),
    );
    return;
  }

  // Locked seat + non-admin → snackbar only
  if (isLocked && !isAdmin && isSeatEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(AudioRoomKeys.seatLocked))),
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
      adminBloc: context.read<AdminBloc>(),
      blacklistBloc: context.read<BlacklistBloc>(),
    );
    return;
  }

  // Own seat or empty seat → show options sheet
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SeatOptionsBody(
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
      adminBloc: context.read<AdminBloc>(),
      blacklistBloc: context.read<BlacklistBloc>(),
    ),
  );
}
