import 'package:flutter/material.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/shared/gifts/gift_bridge.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../audio_room_feature.dart';
import '../audio_room_plugin.dart';
import 'gift_banner_overlay.dart';
import 'gift_event_bus.dart';

class AudioRoomGiftPlugin extends AudioRoomPlugin {
  UTDRoomController? _controller;

  @override
  String get id => 'gifts';

  @override
  String get displayName => 'Gifts';

  @override
  List<String> get rtmMessageTypes => const ['showGifts'];

  @override
  void onControllerReady(UTDRoomController controller) {
    _controller = controller;
  }

  @override
  void onRoomExit(int roomId, String userId) {
    _controller = null;
  }

  @override
  void onRtmMessage(String type, Map<String, dynamic> data) {
    if (type == 'showGifts') {
      GiftEventBus.instance.add(GiftDisplayEvent.fromMap(data));
    }
  }

  @override
  Widget? buildControlsWidget(BuildContext context, int roomId) {
    if (!GiftBridge.instance.isAvailable) return null;
    return IconButton(
      icon: const Icon(Icons.card_giftcard, color: Colors.amberAccent),
      onPressed: () => openPicker(context, roomId),
      tooltip: 'Gift',
    );
  }

  @override
  Widget? buildOverlayWidget(BuildContext context, int roomId) {
    return GiftBannerOverlay(controller: _controller);
  }

  void openPicker(BuildContext context, int roomId) {
    final controller = _controller;
    if (controller == null) return;

    final room = AudioRoomFeature.instance?.activeRoom;
    final ownerId = room?.ownerId ?? 0;

    final seats = controller.seatController.seats.value;
    final recipients = <GiftRecipient>[];
    for (var i = 0; i < seats.length; i++) {
      final seat = seats[i];
      if (seat.occupantUserId != null) {
        final uid = int.tryParse(seat.occupantUserId!);
        if (uid == null) continue;
        recipients.add(GiftRecipient(
          userId: uid,
          name: seat.attributes['name']?.toString() ?? '',
          avatar: seat.attributes['avatar']?.toString(),
          seatIndex: i,
        ));
      }
    }

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No one on seats to gift')),
      );
      return;
    }

    final userData = CacheManager.getUserData();
    final localUserId = userData?['id']?.toString() ?? '';
    final localName = userData?['name']?.toString() ?? '';
    final localProfile = userData?['profile'] as Map?;
    final localAvatar = localProfile?['image']?.toString() ?? '';

    GiftBridge.instance.open(
      context,
      contextType: 'room',
      contextId: roomId,
      roomId: roomId,
      ownerId: ownerId,
      recipients: recipients,
      onRoomGiftSent: ({
        required int giftId,
        required String giftName,
        required String giftImg,
        required String giftShowImg,
        required String giftImageType,
        required bool giftIsPlay,
        required int giftPrice,
        required int giftNum,
        required List<int> recipientIds,
        required int totalCoins,
      }) {
        final data = {
          'send_id': localUserId,
          'send_name': localName,
          'send_avatar': localAvatar,
          'receiver_ids':
              recipientIds.map((id) => id.toString()).toList(),
          'gift_name': giftName,
          'gift_img': giftImg,
          'gift_show_img': giftShowImg,
          'gift_image_type': giftImageType,
          'is_play': giftIsPlay,
          'gift_price': giftPrice,
          'gift_num': giftNum,
        };
        controller.sendRoomMessage({'type': 'showGifts', 'data': data});
        GiftEventBus.instance.add(GiftDisplayEvent.fromMap(data));
      },
    );
  }
}
