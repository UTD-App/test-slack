import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../../domain/entities/real_entity.dart';

abstract class ReelsFeedEvent extends Equatable {
  const ReelsFeedEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load / pull-to-refresh.
class FeedRefreshRequested extends ReelsFeedEvent {
  const FeedRefreshRequested();
}

/// Load the next page.
class FeedLoadMoreRequested extends ReelsFeedEvent {
  const FeedLoadMoreRequested();
}

/// Optimistic Facebook-style reaction toggle. [type] is one of
/// like/love/haha/wow/sad/angry; sending the current type again clears it.
class ReelReactToggled extends ReelsFeedEvent {
  final RealEntity reel;
  final String type;
  const ReelReactToggled(this.reel, this.type);
  @override
  List<Object?> get props => [reel.id, type];
}

/// Adjust a reel's comment counter after a comment/reply is added or deleted in
/// the comments sheet (delta is +1 for an add, negative for a delete).
class ReelCommentCountChanged extends ReelsFeedEvent {
  final int reelId;
  final int delta;
  const ReelCommentCountChanged(this.reelId, this.delta);
  @override
  List<Object?> get props => [reelId, delta];
}

class ReelDeleted extends ReelsFeedEvent {
  final int reelId;
  const ReelDeleted(this.reelId);
  @override
  List<Object?> get props => [reelId];
}

/// Create a new reel, then refresh the feed.
class ReelCreated extends ReelsFeedEvent {
  final File video;
  final String description;
  final List<int> categories;
  const ReelCreated({required this.video, this.description = '', this.categories = const []});
  @override
  List<Object?> get props => [video.path, description, categories];
}

/// Fire-and-forget view tracking (when a reel becomes the active page).
class ReelViewed extends ReelsFeedEvent {
  final int reelId;
  const ReelViewed(this.reelId);
  @override
  List<Object?> get props => [reelId];
}
