import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/moment_like_entity.dart';
import '../../../domain/repositories/moment_repository.dart';

enum LikesStatus { initial, loading, success, failure }

class MomentLikesState extends Equatable {
  final LikesStatus status;
  final List<MomentLikeEntity> likes;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const MomentLikesState({
    this.status = LikesStatus.initial,
    this.likes = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  MomentLikesState copyWith({
    LikesStatus? status,
    List<MomentLikeEntity>? likes,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
  }) =>
      MomentLikesState(
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

class MomentLikesCubit extends Cubit<MomentLikesState> {
  final MomentRepository repository;
  final int momentId;

  MomentLikesCubit(this.repository, this.momentId) : super(const MomentLikesState());

  Future<void> load() async {
    emit(state.copyWith(status: LikesStatus.loading, error: null));
    final res = await repository.fetchLikes(momentId, page: 1);
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
    final res = await repository.fetchLikes(momentId, page: next);
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
