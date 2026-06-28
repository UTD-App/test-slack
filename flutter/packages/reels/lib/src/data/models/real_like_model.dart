import '../../domain/entities/real_like_entity.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

class RealLikeModel extends RealLikeEntity {
  const RealLikeModel({
    required super.userId,
    required super.uuid,
    required super.userName,
    required super.userImage,
    required super.createdAt,
    super.reactionType,
  });

  factory RealLikeModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : const {};
    final type = json['reaction_type']?.toString();
    return RealLikeModel(
      userId: _toInt(user['id'] ?? json['user_id']),
      uuid: user['uuid']?.toString() ?? '',
      userName: user['name']?.toString() ?? '',
      userImage: user['image']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      reactionType: (type == null || type.isEmpty) ? 'like' : type,
    );
  }
}
