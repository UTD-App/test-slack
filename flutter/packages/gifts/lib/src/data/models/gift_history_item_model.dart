import '../../domain/entities/gift_history_item.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
double _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

class GiftHistoryItemModel extends GiftHistoryItem {
  const GiftHistoryItemModel({
    required super.id,
    required super.giftName,
    required super.giftNum,
    required super.totalPrice,
    required super.earned,
    required super.direction,
    required super.createdAt,
  });

  factory GiftHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return GiftHistoryItemModel(
      id: _toInt(json['id']),
      giftName: json['gift_name']?.toString() ?? '',
      giftNum: _toInt(json['gift_num']),
      totalPrice: _toDouble(json['total_price']),
      earned: _toDouble(json['earned']),
      direction: json['direction']?.toString() ?? 'received',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
