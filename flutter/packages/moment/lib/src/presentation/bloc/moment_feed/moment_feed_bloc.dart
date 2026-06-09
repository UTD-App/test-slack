import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/moment_repository.dart';
import 'moment_feed_event.dart';
import 'moment_feed_state.dart';

class MomentFeedBloc extends Bloc<MomentFeedEvent, MomentFeedState> {
  final MomentRepository repository;
  final int type;

  /// When set, the feed is scoped to a single user's moments (their "posts").
  final int? userId;

  MomentFeedBloc(this.repository, {this.type = 4, this.userId}) : super(const MomentFeedState()) {
    on<FeedRefreshRequested>(_onRefresh);
    on<FeedLoadMoreRequested>(_onLoadMore);
    on<MomentLikeToggled>(_onLike);
    on<MomentDeleted>(_onDelete);
    on<MomentCommentAdded>(_onCommentAdded);
    on<MomentGiftSent>(_onGiftSent);
    on<MomentCreated>(_onCreate);
  }

  void _onCommentAdded(MomentCommentAdded event, Emitter<MomentFeedState> emit) {
    final updated = state.moments
        .map((m) => m.id == event.momentId ? m.copyWith(commentNum: m.commentNum + 1) : m)
        .toList();
    emit(state.copyWith(moments: updated));
  }

  void _onGiftSent(MomentGiftSent event, Emitter<MomentFeedState> emit) {
    final updated = state.moments
        .map((m) => m.id == event.momentId ? m.copyWith(giftsCount: m.giftsCount + 1) : m)
        .toList();
    emit(state.copyWith(moments: updated));
  }

  Future<void> _onRefresh(FeedRefreshRequested event, Emitter<MomentFeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.loading, error: null));
    final res = await repository.fetchMoments(type: type, page: 1, userId: userId);
    res.when(
      success: (list) => emit(state.copyWith(
        status: FeedStatus.success,
        moments: list,
        page: 1,
        hasMore: list.isNotEmpty,
      )),
      failure: (msg, _) => emit(state.copyWith(status: FeedStatus.failure, error: msg)),
    );
  }

  Future<void> _onLoadMore(FeedLoadMoreRequested event, Emitter<MomentFeedState> emit) async {
    if (state.isLoadingMore || !state.hasMore || state.status != FeedStatus.success) return;
    emit(state.copyWith(isLoadingMore: true));
    final next = state.page + 1;
    final res = await repository.fetchMoments(type: type, page: next, userId: userId);
    res.when(
      success: (list) => emit(state.copyWith(
        isLoadingMore: false,
        moments: [...state.moments, ...list],
        page: next,
        hasMore: list.isNotEmpty,
      )),
      failure: (msg, _) => emit(state.copyWith(isLoadingMore: false, error: msg)),
    );
  }

  Future<void> _onLike(MomentLikeToggled event, Emitter<MomentFeedState> emit) async {
    // optimistic toggle
    final updated = state.moments.map((m) {
      if (m.id != event.moment.id) return m;
      final liked = !m.isLike;
      return m.copyWith(isLike: liked, likeNum: (m.likeNum + (liked ? 1 : -1)).clamp(0, 1 << 30));
    }).toList();
    emit(state.copyWith(moments: updated));

    final res = await repository.likeMoment(event.moment.id);
    if (res.isFailure) {
      // revert
      emit(state.copyWith(moments: state.moments));
      add(const FeedRefreshRequested());
    }
  }

  Future<void> _onDelete(MomentDeleted event, Emitter<MomentFeedState> emit) async {
    final res = await repository.deleteMoment(event.momentId);
    if (res.isSuccess) {
      emit(state.copyWith(moments: state.moments.where((m) => m.id != event.momentId).toList()));
    }
  }

  Future<void> _onCreate(MomentCreated event, Emitter<MomentFeedState> emit) async {
    emit(state.copyWith(isSubmitting: true, error: null));
    final res = await repository.addMoment(text: event.text, images: event.images);
    emit(state.copyWith(isSubmitting: false));
    if (res.isSuccess && (res.dataOrNull ?? false)) {
      add(const FeedRefreshRequested());
    } else {
      emit(state.copyWith(error: res.dataOrNull == false ? 'Cannot post empty content' : 'Failed to post'));
    }
  }
}
