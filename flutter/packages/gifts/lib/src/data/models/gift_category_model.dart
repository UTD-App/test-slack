import '../../domain/entities/gift_category.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

class GiftCategoryModel extends GiftCategory {
  const GiftCategoryModel({
    required super.id,
    required super.title,
    required super.type,
  });

  factory GiftCategoryModel.fromJson(Map<String, dynamic> json) {
    return GiftCategoryModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'normal',
    );
  }
}
