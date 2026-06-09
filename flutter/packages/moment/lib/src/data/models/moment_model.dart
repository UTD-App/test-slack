import '../../domain/entities/moment_entity.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
bool _toBool(dynamic v) => v == true || v == 1 || v == '1';

class MomentModel extends MomentEntity {
  const MomentModel({
    required super.id,
    required super.userId,
    required super.description,
    required super.img,
    required super.images,
    required super.commentNum,
    required super.likeNum,
    required super.giftsCount,
    required super.isLike,
    required super.createdAt,
    super.isOwner,
    required super.userName,
    required super.userImage,
    required super.uuid,
    required super.gender,
    required super.age,
  });

  factory MomentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : const {};

    final images = <String>[];
    if (json['images'] is List) {
      for (final e in (json['images'] as List)) {
        final v = e is Map ? (e['image']?.toString() ?? '') : e.toString();
        if (v.isNotEmpty) images.add(v);
      }
    }

    return MomentModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      description: json['description']?.toString() ?? '',
      img: json['img']?.toString() ?? '',
      images: images,
      commentNum: _toInt(json['comment_num']),
      likeNum: _toInt(json['like_num']),
      giftsCount: _toInt(json['gifts_count']),
      isLike: _toBool(json['is_like']),
      createdAt: json['created_at']?.toString() ?? '',
      isOwner: _toBool(json['is_owner']),
      userName: user['name']?.toString() ?? '',
      userImage: user['image']?.toString() ?? '',
      uuid: user['uuid']?.toString() ?? '',
      gender: _toInt(user['gender']),
      age: user['age'] == null ? null : _toInt(user['age']),
    );
  }
}
