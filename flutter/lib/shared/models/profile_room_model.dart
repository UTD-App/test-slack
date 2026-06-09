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
}
