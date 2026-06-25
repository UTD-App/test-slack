import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../../domain/entities/moment_entity.dart';

abstract class MomentFeedEvent extends Equatable {
  const MomentFeedEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load / pull-to-refresh.
class FeedRefreshRequested extends MomentFeedEvent {
  const FeedRefreshRequested();
}

/// Load the next page.
class FeedLoadMoreRequested extends MomentFeedEvent {
  const FeedLoadMoreRequested();
}

/// Optimistic like toggle.
class MomentLikeToggled extends MomentFeedEvent {
  final MomentEntity moment;
  const MomentLikeToggled(this.moment);
  @override
  List<Object?> get props => [moment.id];
}

/// Optimistic Facebook-style reaction. Sending the current reaction again
/// removes it (toggle off).
class MomentReacted extends MomentFeedEvent {
  final MomentEntity moment;
  final String reactionType;
  const MomentReacted(this.moment, this.reactionType);
  @override
  List<Object?> get props => [moment.id, reactionType];
}

class MomentDeleted extends MomentFeedEvent {
  final int momentId;
  const MomentDeleted(this.momentId);
  @override
  List<Object?> get props => [momentId];
}

/// A comment was added (from the comments sheet) — bump the card's comment count.
class MomentCommentAdded extends MomentFeedEvent {
  final int momentId;
  const MomentCommentAdded(this.momentId);
  @override
  List<Object?> get props => [momentId];
}

/// One or more comments were deleted (a top-level delete also removes its
/// replies) — drop the card's comment count by [count].
class MomentCommentRemoved extends MomentFeedEvent {
  final int momentId;
  final int count;
  const MomentCommentRemoved(this.momentId, this.count);
  @override
  List<Object?> get props => [momentId, count];
}

/// A gift was sent (from the gift picker) — bump the card's gift total by the
/// coins sent so it updates immediately without a full feed refresh.
class MomentGiftSent extends MomentFeedEvent {
  final int momentId;
  final int coins;
  const MomentGiftSent(this.momentId, this.coins);
  @override
  List<Object?> get props => [momentId, coins];
}

/// Create a new moment, then refresh the feed.
class MomentCreated extends MomentFeedEvent {
  final String text;
  final List<File> images;
  const MomentCreated({required this.text, this.images = const []});
  @override
  List<Object?> get props => [text, images.length];
}
