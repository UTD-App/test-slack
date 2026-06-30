import 'package:utd_app/shared/core/json_coerce.dart';
import 'package:utd_app/shared/entities/profile_room_entity.dart';

class ProfileRoomModel extends ProfileRoomEntity {
  const ProfileRoomModel({
    super.image,
    super.gender,
    super.imageId,
    super.birthday,
    super.age,
  });

  factory ProfileRoomModel.fromJson(Map<String, dynamic> map) {
    // Null-aware coercion: reached from MyDataModel.fromJson on the unguarded
    // launch/cache path, so a type drift (e.g. gender or age arriving as a
    // String) must NOT throw — coerce through num/toString instead.
    return ProfileRoomModel(
      image: map['image']?.toString() ?? '',
      gender: coerceInt(map['gender']),
      imageId: map['image_id']?.toString() ?? '',
      birthday: map['birthday']?.toString() ?? '',
      age: coerceInt(map['age']),
    );
  }

  /// Mirrors [fromJson] so the profile (incl. the avatar URL) survives a cache
  /// round-trip. Without this, MyDataModel.toJson dropped the profile entirely
  /// and the avatar was lost whenever the app loaded the user from cache.
  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'gender': gender,
      'image_id': imageId,
      'birthday': birthday,
      'age': age,
    };
  }
}
