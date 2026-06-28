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

  /// Total coins spent on gifts for this moment (backend `gifts_coins`). Shown
  /// K-formatted next to the gift icon instead of the raw gift count.
  final double giftsCoins;
  final bool isLike;

  /// The current user's reaction type (like/love/haha/wow/sad/angry), or null.
  final String? myReaction;

  /// Per-type reaction counts for the summary, e.g. {like: 5, love: 2}.
  final Map<String, int> reactionsBreakdown;
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
    required this.giftsCoins,
    required this.isLike,
    this.myReaction,
    this.reactionsBreakdown = const {},
    required this.createdAt,
    this.isOwner = false,
    required this.userName,
    required this.userImage,
    required this.uuid,
    required this.gender,
    required this.age,
  });

  MomentEntity copyWith({
    int? likeNum,
    int? commentNum,
    bool? isLike,
    int? giftsCount,
    double? giftsCoins,
    String? myReaction,
    bool clearMyReaction = false,
    Map<String, int>? reactionsBreakdown,
  }) {
    return MomentEntity(
      id: id,
      userId: userId,
      description: description,
      img: img,
      images: images,
      commentNum: commentNum ?? this.commentNum,
      likeNum: likeNum ?? this.likeNum,
      giftsCount: giftsCount ?? this.giftsCount,
      giftsCoins: giftsCoins ?? this.giftsCoins,
      isLike: isLike ?? this.isLike,
      myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
      reactionsBreakdown: reactionsBreakdown ?? this.reactionsBreakdown,
      createdAt: createdAt,
      isOwner: isOwner,
      userName: userName,
      userImage: userImage,
      uuid: uuid,
      gender: gender,
      age: age,
    );
  }

  // Every field the UI mutates optimistically must be here, or Equatable treats
  // the copyWith result as unchanged and the feed won't rebuild. This is why a
  // second gift used to not update the coins counter (giftsCount/giftsCoins were
  // missing): the bloc emitted a "new" state Equatable considered equal.
  @override
  List<Object?> get props => [
        id,
        likeNum,
        commentNum,
        isLike,
        myReaction,
        giftsCount,
        giftsCoins,
        reactionsBreakdown,
      ];
}
