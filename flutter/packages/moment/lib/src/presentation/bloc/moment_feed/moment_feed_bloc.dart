import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/moment_strings.dart';
import '../../../domain/entities/moment_entity.dart';
import '../../../domain/repositories/moment_repository.dart';
import 'moment_feed_event.dart';
import 'moment_feed_state.dart';

class MomentFeedBloc extends Bloc<MomentFeedEvent, MomentFeedState> {
  final MomentRepository repository;
  final int type;

  /// When set, the feed is scoped to a single user's moments (their "posts").
  final int? userId;

  /// Source of the per-refresh shuffle (see [_freshOrder]). A single reused
  /// instance so successive pull-to-refreshes keep producing new orders.
  final Random _random = Random();

  MomentFeedBloc(this.repository, {this.type = 4, this.userId}) : super(const MomentFeedState()) {
    on<FeedStarted>(_onStarted);
    on<FeedRefreshRequested>(_onRefresh);
    on<FeedLoadMoreRequested>(_onLoadMore);
    on<MomentLikeToggled>(_onLike);
    on<MomentReacted>(_onReact);
    on<MomentDeleted>(_onDelete);
    on<MomentCommentAdded>(_onCommentAdded);
    on<MomentCommentRemoved>(_onCommentRemoved);
    on<MomentGiftSent>(_onGiftSent);
    on<MomentCreated>(_onCreate);
  }

  void _onCommentAdded(MomentCommentAdded event, Emitter<MomentFeedState> emit) {
    final updated = state.moments
        .map((m) => m.id == event.momentId ? m.copyWith(commentNum: m.commentNum + 1) : m)
        .toList();
    emit(state.copyWith(moments: updated));
  }

  void _onCommentRemoved(MomentCommentRemoved event, Emitter<MomentFeedState> emit) {
    final updated = state.moments
        .map((m) => m.id == event.momentId
            ? m.copyWith(commentNum: (m.commentNum - event.count).clamp(0, 1 << 30))
            : m)
        .toList();
    emit(state.copyWith(moments: updated));
  }

  void _onGiftSent(MomentGiftSent event, Emitter<MomentFeedState> emit) {
    // Bump both the gift count and the coins total so the K-formatted number next
    // to the gift icon updates immediately (no refresh needed).
    final updated = state.moments
        .map((m) => m.id == event.momentId
            ? m.copyWith(giftsCount: m.giftsCount + 1, giftsCoins: m.giftsCoins + event.coins)
            : m)
        .toList();
    emit(state.copyWith(moments: updated));
  }

  Future<void> _onStarted(FeedStarted event, Emitter<MomentFeedState> emit) async {
    // Instant paint from the on-disk cache (no spinner), then refresh from the
    // network. First run ever (empty cache) falls straight through to the
    // network refresh, which shows the spinner once.
    final cached = await repository.cachedMoments(type: type, userId: userId);
    if (cached.isNotEmpty && state.moments.isEmpty) {
      emit(state.copyWith(
        status: FeedStatus.success,
        moments: cached,
        page: 1,
        hasMore: true,
      ));
    }
    add(const FeedRefreshRequested());
  }

  Future<void> _onRefresh(FeedRefreshRequested event, Emitter<MomentFeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.loading, error: null));
    final res = await repository.fetchMoments(type: type, page: 1, userId: userId);
    res.when(
      success: (page) {
        final list = page.items;
        emit(state.copyWith(
          status: FeedStatus.success,
          // The global feed reshuffles on every pull-to-refresh so the timeline
          // feels live; a user's own scoped posts keep their server (chronological)
          // order. [_freshOrder] guarantees an order that differs from what's
          // currently on screen, so a refresh is always visibly different.
          moments: userId == null ? _freshOrder(list, state.moments) : list,
          page: 1,
          // Prefer the backend's `has_more` meta; fall back to empty-page inference.
          hasMore: page.hasMore ?? list.isNotEmpty,
        ));
      },
      failure: (msg, _) => emit(state.copyWith(status: FeedStatus.failure, error: msg)),
    );
  }

  /// Returns [list] reordered so it differs from [current] (the order already on
  /// screen). With 0–1 items there's nothing to vary, so [list] is returned
  /// as-is; otherwise it shuffles (a few tries) and, as a last resort, swaps the
  /// first two entries — guaranteeing a perceptible change on each refresh.
  List<MomentEntity> _freshOrder(
    List<MomentEntity> list,
    List<MomentEntity> current,
  ) {
    if (list.length < 2) return list;
    final shuffled = List<MomentEntity>.of(list);
    final currentIds = [for (final m in current) m.id];
    for (var attempt = 0; attempt < 6; attempt++) {
      shuffled.shuffle(_random);
      if (!_sameOrder([for (final m in shuffled) m.id], currentIds)) {
        return shuffled;
      }
    }
    final first = shuffled[0];
    shuffled[0] = shuffled[1];
    shuffled[1] = first;
    return shuffled;
  }

  bool _sameOrder(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _onLoadMore(FeedLoadMoreRequested event, Emitter<MomentFeedState> emit) async {
    if (state.isLoadingMore || !state.hasMore || state.status != FeedStatus.success) return;
    emit(state.copyWith(isLoadingMore: true));
    final next = state.page + 1;
    final res = await repository.fetchMoments(type: type, page: next, userId: userId);
    res.when(
      success: (page) => emit(state.copyWith(
        isLoadingMore: false,
        moments: [...state.moments, ...page.items],
        page: next,
        // Prefer the backend's `has_more` meta; fall back to empty-page inference.
        hasMore: page.hasMore ?? page.items.isNotEmpty,
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

  Future<void> _onReact(MomentReacted event, Emitter<MomentFeedState> emit) async {
    final prevMoments = state.moments;
    final updated = state.moments.map((m) {
      if (m.id != event.moment.id) return m;
      final prev = m.myReaction;
      final next = (prev == event.reactionType) ? null : event.reactionType; // same → toggle off
      final delta = (prev == null && next != null) ? 1 : (prev != null && next == null) ? -1 : 0;
      final bd = Map<String, int>.from(m.reactionsBreakdown);
      if (prev != null) {
        final v = (bd[prev] ?? 1) - 1;
        if (v > 0) {
          bd[prev] = v;
        } else {
          bd.remove(prev);
        }
      }
      if (next != null) bd[next] = (bd[next] ?? 0) + 1;
      return m.copyWith(
        myReaction: next,
        clearMyReaction: next == null,
        isLike: next != null,
        likeNum: (m.likeNum + delta).clamp(0, 1 << 30),
        reactionsBreakdown: bd,
      );
    }).toList();
    emit(state.copyWith(moments: updated));

    final res = await repository.reactMoment(event.moment.id, event.reactionType);
    if (res.isFailure) {
      emit(state.copyWith(moments: prevMoments));
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
      // Emit a translation KEY (not raw English); the page resolves it via
      // `context.tr` before showing the SnackBar. `dataOrNull == false` means the
      // backend rejected empty content; anything else is a generic post failure.
      emit(state.copyWith(
        error: res.dataOrNull == false ? MomentStrings.emptyContent : MomentStrings.postFailed,
      ));
    }
  }
}
