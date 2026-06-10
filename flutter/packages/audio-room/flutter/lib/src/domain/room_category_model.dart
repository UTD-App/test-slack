import 'room_category_entity.dart';

class RoomCategoryModel extends RoomCategoryEntity {
  const RoomCategoryModel({
    required super.id,
    super.parentId,
    required super.name,
    super.nameEn,
    super.image,
    super.isEnabled,
    super.children,
  });

  factory RoomCategoryModel.fromJson(Map<String, dynamic> json) {
    final childrenList = (json['children'] as List<dynamic>?)
            ?.map((e) => RoomCategoryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return RoomCategoryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      parentId: (json['parent_id'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      image: json['img'] as String?,
      isEnabled: json['enable'] as bool? ?? true,
      children: childrenList,
    );
  }
}
