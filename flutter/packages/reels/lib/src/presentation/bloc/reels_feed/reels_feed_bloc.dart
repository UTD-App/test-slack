import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/real_entity.dart';
import '../../../domain/repositories/reels_repository.dart';
import 'reels_feed_event.dart';
import 'reels_feed_state.dart';

class ReelsFeedBloc extends Bloc<ReelsFeedEvent, ReelsFeedState> {
  final ReelsRepository repository;

  /// Optional feed filter (e.g. 'following'); null = the main feed.
  final String? filter;

  final _random = Random();

  /// A fresh positive seed (< the prime used by the backend shuffle).
  int _newSeed() => 1 + _random.nextInt(2147483646);

  ReelsFeedBloc(this.repository, {this.filter})
    : super(const ReelsFeedState()) {
    on<FeedRefreshRequested>(_onRefresh);
    on<FeedLoadMoreRequested>(_onLoadMore);
    on<ReelReactToggled>(_onReact);
    on<ReelCommentCountChanged>(_onCommentCountChanged);
    on<ReelDeleted>(_onDelete);
    on<ReelCreated>(_onCreate);
    on<ReelViewed>(_onViewed);
  }

  Future<void> _onRefresh(
    FeedRefreshRequested event,
    Emitter<ReelsFeedState> emit,
  ) async {
    // New seed → a brand-new random order every refresh.
    final seed = _newSeed();
    emit(state.copyWith(status: FeedStatus.loading, error: null, seed: seed));
    final res = await repository.fetchReels(
      page: 1,
      filter: filter,
      seed: seed,
    );
    res.when(
      success: (list) => emit(
        state.copyWith(
          status: FeedStatus.success,
          reels: list,
          page: 1,
          seed: seed,
          hasMore: list.isNotEmpty,
        ),
      ),
      failure: (msg, _) =>
          emit(state.copyWith(status: FeedStatus.failure, error: msg)),
    );
  }

  Future<void> _onLoadMore(
    FeedLoadMoreRequested event,
    Emitter<ReelsFeedState> emit,
  ) async {
    if (state.isLoadingMore || state.status != FeedStatus.success) return;
    emit(state.copyWith(isLoadingMore: true));

    // Keep the same seed while pages remain (stable pagination). When the feed is
    // exhausted, immediately start a fresh random pass from page 1 and append it —
    // an endless, newly shuffled run with no empty step, so the viewer never hits
    // a dead end or a pause.
    var seed = state.hasMore ? state.seed : _newSeed();
    var next = state.hasMore ? state.page + 1 : 1;

    var res = await repository.fetchReels(page: next, filter: filter, seed: seed);
    var list = res.dataOrNull ?? const <RealEntity>[];

    // Ran past the last page → re-randomise and loop from the top in the same go.
    if (res.isSuccess && list.isEmpty) {
      seed = _newSeed();
      next = 1;
      res = await repository.fetchReels(page: next, filter: filter, seed: seed);
      list = res.dataOrNull ?? const <RealEntity>[];
    }

    res.when(
      success: (_) => emit(
        state.copyWith(
          isLoadingMore: false,
          reels: [...state.reels, ...list],
          page: next,
          seed: seed,
          hasMore: list.isNotEmpty,
        ),
      ),
      failure: (msg, _) =>
          emit(state.copyWith(isLoadingMore: false, error: msg)),
    );
  }

  Future<void> _onReact(
    ReelReactToggled event,
    Emitter<ReelsFeedState> emit,
  ) async {
    final previous = state.reels;

    // Optimistic Facebook-style toggle: same type again clears the reaction;
    // otherwise switch to the new one. Keeps likesCount + the per-type breakdown
    // in step so the rail count and "who reacted" summary update instantly.
    final updated = previous.map((r) {
      if (r.id != event.reel.id) return r;
      final prev = r.myReaction;
      final next = (prev == event.type) ? null : event.type;
      final breakdown = Map<String, int>.from(r.reactionsBreakdown);

      if (prev != null) {
        final v = (breakdown[prev] ?? 1) - 1;
        if (v > 0) {
          breakdown[prev] = v;
        } else {
          breakdown.remove(prev);
        }
      }
      if (next != null) breakdown[next] = (breakdown[next] ?? 0) + 1;

      final delta = (prev == null && next != null) ? 1 : (prev != null && next == null) ? -1 : 0;
      return r.copyWith(
        myReaction: next,
        clearMyReaction: next == null,
        isLike: next != null,
        likesCount: (r.likesCount + delta).clamp(0, 1 << 30),
        reactionsBreakdown: breakdown,
      );
    }).toList();
    emit(state.copyWith(reels: updated));

    final res = await repository.reactReel(event.reel.id, event.type);
    if (res.isFailure) {
      // revert
      emit(state.copyWith(reels: previous));
      add(const FeedRefreshRequested());
    }
  }

  void _onCommentCountChanged(
    ReelCommentCountChanged event,
    Emitter<ReelsFeedState> emit,
  ) {
    final updated = state.reels.map((r) {
      if (r.id != event.reelId) return r;
      return r.copyWith(
        commentsCount: (r.commentsCount + event.delta).clamp(0, 1 << 30),
      );
    }).toList();
    emit(state.copyWith(reels: updated));
  }

  Future<void> _onDelete(
    ReelDeleted event,
    Emitter<ReelsFeedState> emit,
  ) async {
    final res = await repository.deleteReel(event.reelId);
    if (res.isSuccess) {
      emit(
        state.copyWith(
          reels: state.reels.where((r) => r.id != event.reelId).toList(),
        ),
      );
    }
  }

  Future<void> _onCreate(
    ReelCreated event,
    Emitter<ReelsFeedState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, error: null));
    final res = await repository.addReel(
      video: event.video,
      description: event.description,
      categories: event.categories,
    );
    emit(state.copyWith(isSubmitting: false));
    if (res.isSuccess && (res.dataOrNull ?? false)) {
      add(const FeedRefreshRequested());
    } else {
      emit(state.copyWith(error: 'Failed to post'));
    }
  }

  Future<void> _onViewed(ReelViewed event, Emitter<ReelsFeedState> emit) async {
    // fire-and-forget; ignore the result
    await repository.recordView(event.reelId);
  }
}
