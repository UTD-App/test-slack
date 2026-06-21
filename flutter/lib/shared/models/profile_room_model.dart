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
    return ProfileRoomModel(
      image: (map['image'] as String?) ?? '',
      gender: (map['gender'] as int?) ?? 0,
      imageId: (map['image_id'] as String?) ?? '',
      birthday: (map['birthday'] as String?) ?? '',
      age: (map['age'] as int?) ?? 0,
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
