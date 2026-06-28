import 'package:flutter/material.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../../audio_room_feature.dart';
import '../../../../audio_room_strings.dart';
import '../shared/room_assets.dart';
import '../messages/room_messages_widget.dart';

class ChatButton extends StatelessWidget {
  final UTDRoomController controller;

  const ChatButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final feature = AudioRoomFeature.instance;
    final localId =
        controller.roomManager.localParticipant?.identity ?? '';

    return ValueListenableBuilder<bool>(
      valueListenable: controller.commentsLocked,
      builder: (context, isLocked, _) {
        final canComment = controller.canIComment;
        final lockedForMe = isLocked && !canComment;

        return ValueListenableBuilder<Set<String>>(
          valueListenable:
              feature?.commentBannedUsers ?? ValueNotifier({}),
          builder: (context, bannedIds, _) {
            final commentBanned = bannedIds.contains(localId);
            final disabled = lockedForMe || commentBanned;

            return GestureDetector(
              onTap: disabled
                  ? commentBanned
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr(AudioRoomKeys.commentsBanned))),
                          );
                        }
                      : null
                  : () => openMessageInput(context, controller),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: disabled
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Opacity(
                    opacity: disabled ? 0.3 : 1.0,
                    child: Image.asset(RoomAssets.chatIcon),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
