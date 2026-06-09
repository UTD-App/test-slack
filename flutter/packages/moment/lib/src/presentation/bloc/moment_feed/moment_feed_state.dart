import 'package:equatable/equatable.dart';

import '../../../domain/entities/moment_entity.dart';

enum FeedStatus { initial, loading, success, failure }

class MomentFeedState extends Equatable {
  final FeedStatus status;
  final List<MomentEntity> moments;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? error;

  const MomentFeedState({
    this.status = FeedStatus.initial,
    this.moments = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.error,
  });

  MomentFeedState copyWith({
    FeedStatus? status,
    List<MomentEntity>? moments,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? error,
  }) {
    return MomentFeedState(
      status: status ?? this.status,
      moments: moments ?? this.moments,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, moments, page, hasMore, isLoadingMore, isSubmitting, error];
}
