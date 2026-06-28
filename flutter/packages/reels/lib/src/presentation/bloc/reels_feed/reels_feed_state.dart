import 'package:equatable/equatable.dart';

import '../../../domain/entities/real_entity.dart';

enum FeedStatus { initial, loading, success, failure }

class ReelsFeedState extends Equatable {
  final FeedStatus status;
  final List<RealEntity> reels;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? error;

  /// Random-order seed for the current feed pass. A fresh seed each refresh
  /// gives a new random order; the same seed keeps pagination stable.
  final int seed;

  const ReelsFeedState({
    this.status = FeedStatus.initial,
    this.reels = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.error,
    this.seed = 0,
  });

  ReelsFeedState copyWith({
    FeedStatus? status,
    List<RealEntity>? reels,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? error,
    int? seed,
  }) {
    return ReelsFeedState(
      status: status ?? this.status,
      reels: reels ?? this.reels,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      seed: seed ?? this.seed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    reels,
    page,
    hasMore,
    isLoadingMore,
    isSubmitting,
    error,
    seed,
  ];
}
