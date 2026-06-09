import '../../domain/entities/moment_comment_entity.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

class MomentCommentModel extends MomentCommentEntity {
  const MomentCommentModel({
    required super.id,
    required super.momentId,
    required super.userId,
    required super.comment,
    required super.createdAt,
    required super.userName,
    required super.userImage,
    required super.uuid,
  });

  factory MomentCommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : const {};
    return MomentCommentModel(
      id: _toInt(json['id']),
      momentId: _toInt(json['moment_id']),
      userId: _toInt(json['user_id']),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      userName: user['name']?.toString() ?? '',
      userImage: user['image']?.toString() ?? '',
      uuid: user['uuid']?.toString() ?? '',
    );
  }
}
