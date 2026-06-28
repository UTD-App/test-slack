import '../../domain/entities/real_entity.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
bool _toBool(dynamic v) => v == true || v == 1 || v == '1';

/// Parse the backend `reactions` breakdown object ({"like":3,"love":1}).
Map<String, int> _toReactions(dynamic v) {
  final out = <String, int>{};
  if (v is Map) {
    v.forEach((k, val) => out['$k'] = _toInt(val));
  }
  return out;
}

class RealModel extends RealEntity {
  const RealModel({
    required super.id,
    required super.userId,
    required super.description,
    required super.url,
    required super.subVideo,
    required super.subFrame,
    required super.likesCount,
    required super.commentsCount,
    super.viewsCount,
    required super.isLike,
    required super.shareCount,
    required super.createdAt,
    super.myReaction,
    super.reactionsBreakdown,
    super.isOwner,
    required super.userName,
    required super.userImage,
    required super.uuid,
    required super.gender,
    required super.age,
  });

  factory RealModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : const {};

    return RealModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      subVideo: json['sub_video']?.toString() ?? '',
      subFrame: json['sub_frame']?.toString() ?? '',
      likesCount: _toInt(json['likes_count']),
      commentsCount: _toInt(json['comments_count']),
      viewsCount: _toInt(json['views_count']),
      isLike: _toBool(json['likes_exists']),
      shareCount: _toInt(json['share_count']),
      createdAt: json['created_at']?.toString() ?? '',
      myReaction: json['my_reaction']?.toString().isEmpty ?? true ? null : json['my_reaction'].toString(),
      reactionsBreakdown: _toReactions(json['reactions']),
      isOwner: _toBool(json['is_owner']),
      userName: user['name']?.toString() ?? '',
      userImage: user['image']?.toString() ?? '',
      uuid: user['uuid']?.toString() ?? '',
      gender: _toInt(user['gender']),
      age: user['age'] == null ? null : _toInt(user['age']),
    );
  }
}
