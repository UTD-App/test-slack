import 'package:flutter/widgets.dart';

/// A potential gift recipient — e.g. a user seated in a room. Passed to the gift
/// picker (via [GiftBridge.open]) so the sender can choose who to gift among the
/// people on the seats. Used only for room gifting; moment/reel gifts have a
/// single implicit receiver and don't pass recipients.
class GiftRecipient {
  final int userId;
  final String name;
  final String? avatar;
  final int? seatIndex;

  const GiftRecipient({
    required this.userId,
    required this.name,
    this.avatar,
    this.seatIndex,
  });
}

/// Fired after a successful ROOM gift send with the full sent-gift details, so the
/// room can broadcast it (RTM) and play the banner/animation for everyone. Only
/// invoked for room gifting; [GiftLauncher.onSent] still fires for all sends.
typedef RoomGiftSentCallback = void Function({
  required int giftId,
  required String giftName,
  required String giftImg,
  required String giftShowImg,
  required String giftImageType,
  required int giftPrice,
  required int giftNum,
  required List<int> recipientIds,
  required int totalCoins,
});

/// How the Gifts package opens its picker. Receives the context the gift is
/// sent in (e.g. a moment) so the picker can post to the right endpoint, plus an
/// optional [onSent] the picker fires after a successful send — with the total
/// COINS sent — so the host can update its UI (e.g. bump the moment's gift total)
/// without a full refresh.
///
/// Room gifting passes the extra [roomId]/[ownerId]/[recipients]: when
/// [recipients] is non-null the picker shows a recipient selector and sends to the
/// chosen seats via POST /api/gifts/send. When they're null it behaves exactly as
/// before (moment/reel: single implicit receiver).
typedef GiftLauncher = void Function(
  BuildContext context, {
  required String contextType,
  required int contextId,
  String? receiverName,
  void Function(int coins)? onSent,
  int? roomId,
  int? ownerId,
  List<GiftRecipient>? recipients,
  RoomGiftSentCallback? onRoomGiftSent,
});

/// Flutter analog of the backend `App\Contracts\GiftSender` seam.
///
/// A host feature (Moment, Reels, Room…) lets a user send a gift WITHOUT depending
/// on the Gifts package: it calls [GiftBridge.instance.open]. The Gifts package
/// registers the launcher at startup ([register]). When Gifts isn't installed,
/// [isAvailable] is false and the host simply hides its gift button.
class GiftBridge {
  GiftBridge._();

  static final GiftBridge instance = GiftBridge._();

  GiftLauncher? _launcher;

  bool get isAvailable => _launcher != null;

  void register(GiftLauncher launcher) => _launcher = launcher;

  void open(
    BuildContext context, {
    required String contextType,
    required int contextId,
    String? receiverName,
    void Function(int coins)? onSent,
    int? roomId,
    int? ownerId,
    List<GiftRecipient>? recipients,
    RoomGiftSentCallback? onRoomGiftSent,
  }) {
    _launcher?.call(
      context,
      contextType: contextType,
      contextId: contextId,
      receiverName: receiverName,
      onSent: onSent,
      roomId: roomId,
      ownerId: ownerId,
      recipients: recipients,
      onRoomGiftSent: onRoomGiftSent,
    );
  }
}
