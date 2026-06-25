import '../../domain/entities/moment_comment_entity.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;

/// Parse the backend `reactions` breakdown object ({"like":3,"love":1}).
Map<String, int> _toReactions(dynamic v) {
  final out = <String, int>{};
  if (v is Map) {
    v.forEach((k, val) => out['$k'] = _toInt(val));
  }
  return out;
}

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
    super.parentId,
    super.replies,
    super.likeNum,
    super.myReaction,
    super.reactionsBreakdown,
  });

  factory MomentCommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : const {};
    final replies = <MomentCommentEntity>[];
    if (json['replies'] is List) {
      for (final e in (json['replies'] as List)) {
        if (e is Map) replies.add(MomentCommentModel.fromJson(e.cast<String, dynamic>()));
      }
    }
    return MomentCommentModel(
      id: _toInt(json['id']),
      momentId: _toInt(json['moment_id']),
      userId: _toInt(json['user_id']),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      userName: user['name']?.toString() ?? '',
      userImage: user['image']?.toString() ?? '',
      uuid: user['uuid']?.toString() ?? '',
      parentId: json['parent_id'] == null ? null : _toInt(json['parent_id']),
      replies: replies,
      likeNum: _toInt(json['like_num']),
      myReaction: json['my_reaction']?.toString().isEmpty ?? true ? null : json['my_reaction'].toString(),
      reactionsBreakdown: _toReactions(json['reactions']),
    );
  }
}
