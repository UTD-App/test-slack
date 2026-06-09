import 'package:equatable/equatable.dart';

class MomentCommentEntity extends Equatable {
  final int id;
  final int momentId;
  final int userId;
  final String comment;
  final String createdAt;
  final String userName;
  final String userImage;
  final String uuid;

  const MomentCommentEntity({
    required this.id,
    required this.momentId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.userName,
    required this.userImage,
    required this.uuid,
  });

  @override
  List<Object?> get props => [id];
}
