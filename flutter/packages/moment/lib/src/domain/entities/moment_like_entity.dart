import 'package:equatable/equatable.dart';

class MomentLikeEntity extends Equatable {
  final int userId;
  final String uuid;
  final String userName;
  final String userImage;
  final String createdAt;

  const MomentLikeEntity({
    required this.userId,
    required this.uuid,
    required this.userName,
    required this.userImage,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [userId, createdAt];
}
