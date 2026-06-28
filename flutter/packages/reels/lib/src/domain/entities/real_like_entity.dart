import 'package:equatable/equatable.dart';

class RealLikeEntity extends Equatable {
  final int userId;
  final String uuid;
  final String userName;
  final String userImage;
  final String createdAt;

  /// The Facebook-style reaction this user gave (like/love/haha/wow/sad/angry).
  /// Defaults to 'like' for back-compat with rows stored before reactions.
  final String reactionType;

  const RealLikeEntity({
    required this.userId,
    required this.uuid,
    required this.userName,
    required this.userImage,
    required this.createdAt,
    this.reactionType = 'like',
  });

  @override
  List<Object?> get props => [userId, createdAt, reactionType];
}
