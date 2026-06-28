import '../../domain/entities/gift.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

class GiftModel extends Gift {
  const GiftModel({
    required super.id,
    required super.name,
    required super.type,
    required super.categoryId,
    required super.price,
    required super.img,
    required super.showImg,
    required super.imageType,
    required super.vipLevel,
    super.isPlay,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: _toInt(json['type']),
      categoryId: json['category_id'] == null ? null : _toInt(json['category_id']),
      price: _toInt(json['price']),
      img: json['img']?.toString() ?? '',
      showImg: json['show_img']?.toString() ?? '',
      imageType: json['image_type']?.toString() ?? '',
      vipLevel: _toInt(json['vip_level']),
      isPlay: json['is_play'] == true || json['is_play'] == 1 || json['is_play'] == '1',
    );
  }
}
