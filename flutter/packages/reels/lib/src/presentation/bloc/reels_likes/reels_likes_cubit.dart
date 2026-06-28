import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/real_like_entity.dart';
import '../../../domain/repositories/reels_repository.dart';

enum LikesStatus { initial, loading, success, failure }

class ReelsLikesState extends Equatable {
  final LikesStatus status;
  final List<RealLikeEntity> likes;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const ReelsLikesState({
    this.status = LikesStatus.initial,
    this.likes = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  ReelsLikesState copyWith({
    LikesStatus? status,
    List<RealLikeEntity>? likes,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
  }) =>
      ReelsLikesState(
        status: status ?? this.status,
        likes: likes ?? this.likes,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error,
      );

  @override
  List<Object?> get props => [status, likes, isLoadingMore, hasMore, page, error];
}

class ReelsLikesCubit extends Cubit<ReelsLikesState> {
  final ReelsRepository repository;
  final int reelId;

  ReelsLikesCubit(this.repository, this.reelId) : super(const ReelsLikesState());

  Future<void> load() async {
    emit(state.copyWith(status: LikesStatus.loading, error: null));
    final res = await repository.fetchLikes(reelId, page: 1);
    res.when(
      success: (list) => emit(state.copyWith(
        status: LikesStatus.success,
        likes: list,
        page: 1,
        hasMore: list.isNotEmpty,
      )),
      failure: (msg, _) => emit(state.copyWith(status: LikesStatus.failure, error: msg)),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.status != LikesStatus.success) return;
    emit(state.copyWith(isLoadingMore: true));
    final next = state.page + 1;
    final res = await repository.fetchLikes(reelId, page: next);
    res.when(
      success: (list) => emit(state.copyWith(
        isLoadingMore: false,
        likes: [...state.likes, ...list],
        page: next,
        hasMore: list.isNotEmpty,
      )),
      failure: (_, __) => emit(state.copyWith(isLoadingMore: false)),
    );
  }
}
