import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../bloc/admin/admin_bloc.dart';
import '../../../bloc/blacklist/blacklist_bloc.dart';
import 'user_profile_body.dart';

Future<void> showUserProfileSheet(
  BuildContext context, {
  required UTDRoomController controller,
  required SeatState seat,
  required String localUserId,
  required bool isOwner,
  required int roomId,
  required AdminBloc adminBloc,
  required BlacklistBloc blacklistBloc,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: adminBloc),
        BlocProvider.value(value: blacklistBloc),
      ],
      child: UserProfileBody(
        controller: controller,
        seat: seat,
        localUserId: localUserId,
        isOwner: isOwner,
        roomId: roomId,
      ),
    ),
  );
}
