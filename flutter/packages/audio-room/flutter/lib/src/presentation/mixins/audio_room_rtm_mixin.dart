import 'dart:async';

import 'package:flutter/material.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../audio_room_feature.dart';
import '../../domain/room_model.dart';
import '../widgets/room/room_strings.dart';

mixin AudioRoomRtmMixin {
  bool get mounted;
  BuildContext get context;
  void setState(VoidCallback fn);

  RoomModel? get currentRoom;
  set currentRoom(RoomModel? value);
  UTDRoomController? get roomController;

  StreamSubscription? joinSub;
  StreamSubscription? leaveSub;
  StreamSubscription? dataSub;

  void disposeRtm() {
    joinSub?.cancel();
    leaveSub?.cancel();
    dataSub?.cancel();
  }

  void listenPluginMessages(UTDRoomController controller) {
    dataSub = controller.dataStream.listen((data) {
      final type = data['type'] as String?;
      if (type == null) return;

      if (type == 'roleChange') {
        _handleRoleChangeRtm(data['data'] as Map<String, dynamic>? ?? data);
        return;
      }

      if (type == 'roomSettingsUpdate') {
        _handleRoomSettingsUpdateRtm(
          data['data'] as Map<String, dynamic>? ?? data,
        );
        return;
      }

      if (type == 'commentBan') {
        _handleCommentBanRtm(
          data['data'] as Map<String, dynamic>? ?? data,
        );
        return;
      }

      if (type == 'pinMessage') {
        _handlePinMessageRtm(data['data'] as Map<String, dynamic>?);
        return;
      }

      if (type == 'unpinMessage') {
        AudioRoomFeature.instance?.pinnedMessage.value = null;
        return;
      }

      if (type == 'deleteMessage') {
        _handleDeleteMessageRtm(data);
        return;
      }

      for (final plugin in AudioRoomFeature.registeredPlugins) {
        if (plugin.rtmMessageTypes.contains(type)) {
          plugin.onRtmMessage(
            type,
            data['data'] as Map<String, dynamic>? ?? data,
          );
        }
      }
    });
  }

  void _handleRoleChangeRtm(Map<String, dynamic> data) {
    if (!mounted) return;
    final targetUserId = data['user_id']?.toString();
    final role = data['role']?.toString();
    if (targetUserId == null || role == null) return;

    final localUserId = CacheManager.getUserData()?['id']?.toString() ?? '';
    final isPromotion = role == 'admin';

    if (targetUserId == localUserId) {
      setState(() {
        currentRoom = currentRoom?.copyWith(isAdmin: isPromotion);
      });
    }
  }

  void _handleRoomSettingsUpdateRtm(Map<String, dynamic> data) {
    if (!mounted || currentRoom == null) return;
    final commentsClosed = data['is_comment_closed'] as bool?;
    setState(() {
      currentRoom = currentRoom!.copyWith(
        roomName: data['room_name']?.toString(),
        roomCover: data['room_cover']?.toString(),
        roomIntro: data['room_intro']?.toString(),
        roomRule: data['room_rule']?.toString(),
        roomBackground: data['room_background']?.toString(),
        freeMic: data['free_mic'] as bool?,
        isCommentsClosed: commentsClosed,
        hasPassword: data['has_password'] as bool?,
        mode: data['mode'] as int?,
        emptySeatIcon: data.containsKey('empty_seat_icon')
            ? () => data['empty_seat_icon']?.toString()
            : null,
        lockedSeatIcon: data.containsKey('locked_seat_icon')
            ? () => data['locked_seat_icon']?.toString()
            : null,
      );
    });
    if (commentsClosed != null) {
      roomController?.commentsLocked.value = commentsClosed;
    }
  }

  void listenParticipantEvents(UTDRoomController controller) {
    final s = RoomStrings.of(context);
    joinSub = controller.roomManager.participantJoinedStream.listen((p) {
      final name = p.name.isNotEmpty ? p.name : p.identity;
      controller.chatController.addDisplayMessage(
        UTDChatMessage(
          senderUserId: 'system',
          senderName: '',
          text: s.userJoined(name),
          timestamp: DateTime.now(),
        ),
      );
    });
    leaveSub = controller.roomManager.participantLeftStream.listen((p) {
      final name = p.name.isNotEmpty ? p.name : p.identity;
      controller.chatController.addDisplayMessage(
        UTDChatMessage(
          senderUserId: 'system',
          senderName: '',
          text: s.userLeft(name),
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _handleCommentBanRtm(Map<String, dynamic> data) {
    final feature = AudioRoomFeature.instance;
    if (feature == null) return;
    final userId = data['user_id']?.toString();
    final banned = data['banned'] as bool? ?? false;
    if (userId == null) return;

    final updated = Set<String>.from(feature.commentBannedUsers.value);
    if (banned) {
      updated.add(userId);
    } else {
      updated.remove(userId);
    }
    feature.commentBannedUsers.value = updated;
  }

  void _handlePinMessageRtm(Map<String, dynamic>? data) {
    final feature = AudioRoomFeature.instance;
    if (feature == null || data == null) return;
    feature.pinnedMessage.value = data;
  }

  void _handleDeleteMessageRtm(Map<String, dynamic> data) {
    final messageID = data['messageID']?.toString();
    if (messageID == null) return;
    final chat = roomController?.chatController;
    if (chat == null) return;
    chat.messages.value =
        chat.messages.value.where((m) => m.messageID != messageID).toList();
  }

  void broadcastRoomSettingsUpdate(RoomModel room) {
    roomController?.sendRoomMessage({
      'type': 'roomSettingsUpdate',
      'data': {
        'room_name': room.roomName,
        'room_cover': room.roomCover,
        'room_intro': room.roomIntro,
        'room_rule': room.roomRule,
        'room_background': room.roomBackground,
        'free_mic': room.freeMic,
        'is_comment_closed': room.isCommentsClosed,
        'has_password': room.hasPassword,
        'mode': room.mode,
        'empty_seat_icon': room.emptySeatIcon,
        'locked_seat_icon': room.lockedSeatIcon,
      },
    });
  }
}
