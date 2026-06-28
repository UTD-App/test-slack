import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../../audio_room_feature.dart';
import '../../../../audio_room_strings.dart';
import '../../../bloc/room_management/room_management_bloc.dart';

void showMessageActionsSheet(
  BuildContext context, {
  required UTDChatMessage message,
  required UTDRoomController controller,
  required bool isPinned,
  required String? avatarUrl,
  required int roomId,
}) {
  final feature = AudioRoomFeature.instance;
  if (feature == null) return;

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPinned)
              ListTile(
                leading: const Icon(Icons.push_pin_outlined, color: Colors.red),
                title: Text(
                  context.tr(AudioRoomKeys.unpinMessage),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  feature.pinnedMessage.value = null;
                  controller.sendRoomMessage({'type': 'unpinMessage'});
                  context.read<RoomManagementBloc>().add(
                    UnpinMessageEvent(roomId: roomId),
                  );
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(context.tr(AudioRoomKeys.messageUnpinned))));
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.push_pin, color: Colors.amber),
                title: Text(
                  context.tr(AudioRoomKeys.pinMessage),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final data = {
                    'senderId': message.userData['senderId']?.toString() ??
                        message.senderUserId,
                    'senderName': message.senderName,
                    'text': message.text,
                    'senderAvatar': avatarUrl ?? '',
                    'timestamp': message.timestamp.millisecondsSinceEpoch,
                  };
                  feature.pinnedMessage.value = data;
                  controller.sendRoomMessage({
                    'type': 'pinMessage',
                    'data': data,
                  });
                  context.read<RoomManagementBloc>().add(
                    PinMessageEvent(roomId: roomId, data: data),
                  );
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(context.tr(AudioRoomKeys.messagePinned))));
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                context.tr(AudioRoomKeys.deleteMessage),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                final chat = controller.chatController;
                chat.messages.value = chat.messages.value
                    .where((m) => m.messageID != message.messageID)
                    .toList();
                controller.sendRoomMessage({
                  'type': 'deleteMessage',
                  'messageID': message.messageID,
                });
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(context.tr(AudioRoomKeys.messageDeleted))));
              },
            ),
          ],
        ),
      ),
    ),
  );
}
