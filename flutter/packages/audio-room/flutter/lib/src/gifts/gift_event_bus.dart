import 'dart:async';

class GiftDisplayEvent {
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final List<String> receiverIds;
  final String giftName;
  final String giftImg;
  final String giftShowImg;
  final String giftImageType;
  final int giftPrice;
  final int giftNum;
  final bool isPlay;

  const GiftDisplayEvent({
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverIds,
    required this.giftName,
    required this.giftImg,
    this.giftShowImg = '',
    this.giftImageType = '',
    required this.giftPrice,
    required this.giftNum,
    this.isPlay = false,
  });

  factory GiftDisplayEvent.fromMap(Map<String, dynamic> data) {
    final rawReceivers = data['receiver_ids'];
    final List<String> receivers;
    if (rawReceivers is List) {
      receivers = rawReceivers.map((e) => e.toString()).toList();
    } else if (rawReceivers is String) {
      receivers = rawReceivers.split(',').map((e) => e.trim()).toList();
    } else {
      receivers = const [];
    }

    return GiftDisplayEvent(
      senderId: data['send_id']?.toString() ?? '',
      senderName: data['send_name']?.toString() ?? '',
      senderAvatar: data['send_avatar']?.toString(),
      receiverIds: receivers,
      giftName: data['gift_name']?.toString() ?? '',
      giftImg: data['gift_img']?.toString() ?? '',
      giftShowImg: data['gift_show_img']?.toString() ?? '',
      giftImageType: data['gift_image_type']?.toString() ?? '',
      giftPrice: (data['gift_price'] as num?)?.toInt() ?? 0,
      giftNum: (data['gift_num'] as num?)?.toInt() ?? 1,
      isPlay: data['is_play'] == true || data['is_play'] == 1,
    );
  }
}

class GiftEventBus {
  GiftEventBus._();
  static final instance = GiftEventBus._();

  final _controller = StreamController<GiftDisplayEvent>.broadcast();

  Stream<GiftDisplayEvent> get stream => _controller.stream;

  void add(GiftDisplayEvent event) => _controller.add(event);
}
