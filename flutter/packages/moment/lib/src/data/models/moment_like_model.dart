import '../../domain/entities/moment_like_entity.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

class MomentLikeModel extends MomentLikeEntity {
  const MomentLikeModel({
    required super.userId,
    required super.uuid,
    required super.userName,
    required super.userImage,
    required super.createdAt,
  });

  factory MomentLikeModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : const {};
    return MomentLikeModel(
      userId: _toInt(user['id'] ?? json['user_id']),
      uuid: user['uuid']?.toString() ?? '',
      userName: user['name']?.toString() ?? '',
      userImage: user['image']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
