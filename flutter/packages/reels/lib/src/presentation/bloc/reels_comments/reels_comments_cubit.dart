import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/real_comment_entity.dart';
import '../../../domain/repositories/reels_repository.dart';

enum CommentsStatus { initial, loading, success, failure }

class ReelsCommentsState extends Equatable {
  final CommentsStatus status;
  final List<RealCommentEntity> comments;
  final bool isSubmitting;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const ReelsCommentsState({
    this.status = CommentsStatus.initial,
    this.comments = const [],
    this.isSubmitting = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  ReelsCommentsState copyWith({
    CommentsStatus? status,
    List<RealCommentEntity>? comments,
    bool? isSubmitting,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
  }) =>
      ReelsCommentsState(
        status: status ?? this.status,
        comments: comments ?? this.comments,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error,
      );

  @override
  List<Object?> get props => [status, comments, isSubmitting, isLoadingMore, hasMore, page, error];
}

class ReelsCommentsCubit extends Cubit<ReelsCommentsState> {
  final ReelsRepository repository;
  final int reelId;

  ReelsCommentsCubit(this.repository, this.reelId) : super(const ReelsCommentsState());

  Future<void> load() async {
    emit(state.copyWith(status: CommentsStatus.loading, error: null));
    final res = await repository.fetchComments(reelId, page: 1);
    res.when(
      success: (list) => emit(state.copyWith(
        status: CommentsStatus.success,
        comments: list,
        page: 1,
        hasMore: list.isNotEmpty,
      )),
      failure: (msg, _) => emit(state.copyWith(status: CommentsStatus.failure, error: msg)),
    );
  }

  /// Append the next page of top-level comments (each with its replies).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.status != CommentsStatus.success) return;
    emit(state.copyWith(isLoadingMore: true));
    final next = state.page + 1;
    final res = await repository.fetchComments(reelId, page: next);
    res.when(
      success: (list) => emit(state.copyWith(
        isLoadingMore: false,
        comments: [...state.comments, ...list],
        page: next,
        hasMore: list.isNotEmpty,
      )),
      failure: (_, __) => emit(state.copyWith(isLoadingMore: false)),
    );
  }

  Future<bool> add(String text, {int? parentId}) async {
    if (text.trim().isEmpty) return false;
    emit(state.copyWith(isSubmitting: true));
    final res = await repository.addComment(reelId, text.trim(), parentId: parentId);
    emit(state.copyWith(isSubmitting: false));
    if (res.isSuccess) {
      await load();
      return true;
    }
    return false;
  }

  /// Delete a comment or reply (server authorizes: author or reel owner).
  /// Removes it from the local tree on success and returns how many rows were
  /// removed (a top-level comment also takes its replies) — 0 means failure.
  Future<int> delete(int commentId) async {
    final res = await repository.deleteComment(reelId, commentId);
    if (!res.isSuccess) return 0;

    var removed = 0;
    final updated = <RealCommentEntity>[];
    for (final c in state.comments) {
      if (c.id == commentId) {
        removed = 1 + c.replies.length; // top-level: it + its replies cascade
        continue;
      }
      if (c.replies.any((r) => r.id == commentId)) {
        removed = 1;
        updated.add(c.copyWith(replies: c.replies.where((r) => r.id != commentId).toList()));
      } else {
        updated.add(c);
      }
    }
    emit(state.copyWith(comments: updated));
    return removed;
  }

  Future<bool> report(int commentId, {required String description, required String type}) async {
    final res = await repository.reportComment(reelId, commentId, description: description, type: type);
    return res.isSuccess;
  }

  /// Toggle a Facebook-style reaction on a comment or reply. Optimistic: updates
  /// the matching node anywhere in the comment/reply tree, reverting on failure.
  Future<void> react(int commentId, String type) async {
    final previous = state.comments;
    final updated = previous.map((c) => _applyReaction(c, commentId, type)).toList();
    emit(state.copyWith(comments: updated));

    final res = await repository.reactComment(reelId, commentId, type);
    if (res.isFailure) {
      emit(state.copyWith(comments: previous));
    }
  }

  RealCommentEntity _applyReaction(RealCommentEntity c, int commentId, String type) {
    if (c.id == commentId) return _toggleReaction(c, type);
    if (c.replies.isNotEmpty) {
      return c.copyWith(replies: c.replies.map((r) => _applyReaction(r, commentId, type)).toList());
    }
    return c;
  }

  RealCommentEntity _toggleReaction(RealCommentEntity c, String type) {
    final prev = c.myReaction;
    final next = (prev == type) ? null : type; // same type → toggle off
    final breakdown = Map<String, int>.from(c.reactionsBreakdown);

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
    return c.copyWith(
      myReaction: next,
      clearMyReaction: next == null,
      likeNum: (c.likeNum + delta).clamp(0, 1 << 30),
      reactionsBreakdown: breakdown,
    );
  }
}
