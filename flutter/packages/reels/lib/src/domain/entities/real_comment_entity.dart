import 'package:equatable/equatable.dart';

class RealCommentEntity extends Equatable {
  final int id;
  final int realId;
  final int userId;
  final String comment;
  final String createdAt;
  final String userName;
  final String userImage;
  final String uuid;

  /// The comment this one replies to (null = top-level).
  final int? parentId;

  /// One level of replies under a top-level comment.
  final List<RealCommentEntity> replies;

  /// Total reactions on this comment (backend `like_num`).
  final int likeNum;

  /// The current user's reaction type (like/love/haha/wow/sad/angry), or null.
  final String? myReaction;

  /// Per-type reaction counts, e.g. {like: 3, love: 1}.
  final Map<String, int> reactionsBreakdown;

  const RealCommentEntity({
    required this.id,
    required this.realId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.userName,
    required this.userImage,
    required this.uuid,
    this.parentId,
    this.replies = const [],
    this.likeNum = 0,
    this.myReaction,
    this.reactionsBreakdown = const {},
  });

  RealCommentEntity copyWith({
    List<RealCommentEntity>? replies,
    int? likeNum,
    String? myReaction,
    bool clearMyReaction = false,
    Map<String, int>? reactionsBreakdown,
  }) {
    return RealCommentEntity(
      id: id,
      realId: realId,
      userId: userId,
      comment: comment,
      createdAt: createdAt,
      userName: userName,
      userImage: userImage,
      uuid: uuid,
      parentId: parentId,
      replies: replies ?? this.replies,
      likeNum: likeNum ?? this.likeNum,
      myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
      reactionsBreakdown: reactionsBreakdown ?? this.reactionsBreakdown,
    );
  }

  @override
  List<Object?> get props => [id, replies, likeNum, myReaction];
}
