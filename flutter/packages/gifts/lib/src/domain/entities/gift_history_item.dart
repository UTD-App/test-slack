import 'package:equatable/equatable.dart';

/// One row of the user's gift history (sent or received).
class GiftHistoryItem extends Equatable {
  final int id;
  final String giftName;
  final int giftNum;
  final double totalPrice;
  final double earned;
  final String direction; // sent | received
  final String createdAt;

  const GiftHistoryItem({
    required this.id,
    required this.giftName,
    required this.giftNum,
    required this.totalPrice,
    required this.earned,
    required this.direction,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
