import 'package:equatable/equatable.dart';

/// A single moment (post) in the feed.
///
/// Simplified to match the base-project backend (utd/moment). Rich fields
/// (vip, levels, frames, gifts) are intentionally omitted — see NOTES_GAPS.md.
class MomentEntity extends Equatable {
  final int id;
  final int userId;
  final String description;
  final String img;
  final List<String> images;
  final int commentNum;
  final int likeNum;
  final int giftsCount;
  final bool isLike;
  final String createdAt;

  /// True when the current user authored this moment (from backend `is_owner`).
  /// Controls whether the delete action is offered for this card.
  final bool isOwner;

  // author (flattened from the nested `user` object)
  final String userName;
  final String userImage;
  final String uuid;
  final int gender;
  final int? age;

  const MomentEntity({
    required this.id,
    required this.userId,
    required this.description,
    required this.img,
    required this.images,
    required this.commentNum,
    required this.likeNum,
    required this.giftsCount,
    required this.isLike,
    required this.createdAt,
    this.isOwner = false,
    required this.userName,
    required this.userImage,
    required this.uuid,
    required this.gender,
    required this.age,
  });

  MomentEntity copyWith({int? likeNum, int? commentNum, bool? isLike}) {
    return MomentEntity(
      id: id,
      userId: userId,
      description: description,
      img: img,
      images: images,
      commentNum: commentNum ?? this.commentNum,
      likeNum: likeNum ?? this.likeNum,
      giftsCount: giftsCount,
      isLike: isLike ?? this.isLike,
      createdAt: createdAt,
      isOwner: isOwner,
      userName: userName,
      userImage: userImage,
      uuid: uuid,
      gender: gender,
      age: age,
    );
  }

  @override
  List<Object?> get props => [id, likeNum, commentNum, isLike];
}
