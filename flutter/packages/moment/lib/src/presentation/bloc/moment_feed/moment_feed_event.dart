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

/// A gift was sent (from the gift picker) — bump the card's gift count so it
/// updates immediately without a full feed refresh.
class MomentGiftSent extends MomentFeedEvent {
  final int momentId;
  const MomentGiftSent(this.momentId);
  @override
  List<Object?> get props => [momentId];
}

/// Create a new moment, then refresh the feed.
class MomentCreated extends MomentFeedEvent {
  final String text;
  final List<File> images;
  const MomentCreated({required this.text, this.images = const []});
  @override
  List<Object?> get props => [text, images.length];
}
