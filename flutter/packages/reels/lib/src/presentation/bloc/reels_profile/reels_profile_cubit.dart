import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/real_entity.dart';
import '../../../domain/repositories/reels_repository.dart';

enum ReelsProfileStatus { initial, loading, success, failure }

class ReelsProfileState extends Equatable {
  final ReelsProfileStatus status;
  final List<RealEntity> reels;
  final String? error;

  const ReelsProfileState({
    this.status = ReelsProfileStatus.initial,
    this.reels = const [],
    this.error,
  });

  ReelsProfileState copyWith({
    ReelsProfileStatus? status,
    List<RealEntity>? reels,
    String? error,
  }) {
    return ReelsProfileState(
      status: status ?? this.status,
      reels: reels ?? this.reels,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, reels, error];
}

/// Drives the "My / a user's reels" grid (and the full-screen playback opened
/// from it). [userId] null = the current user's own reels (`/reals/my-reals`),
/// otherwise that user's public reels (`/reals/user/{id}`). All three mutating
/// actions reuse the existing [ReelsRepository] endpoints.
class ReelsProfileCubit extends Cubit<ReelsProfileState> {
  final ReelsRepository repository;
  final int? userId;

  ReelsProfileCubit(this.repository, {this.userId})
      : super(const ReelsProfileState());

  Future<void> load() async {
    emit(state.copyWith(status: ReelsProfileStatus.loading, error: null));
    final res = userId == null
        ? await repository.fetchMyReals()
        : await repository.fetchUserReals(userId!);
    res.when(
      success: (list) =>
          emit(state.copyWith(status: ReelsProfileStatus.success, reels: list)),
      failure: (msg, _) =>
          emit(state.copyWith(status: ReelsProfileStatus.failure, error: msg)),
    );
  }

  Future<void> deleteReel(int reelId) async {
    final res = await repository.deleteReel(reelId);
    if (res.isSuccess) {
      emit(state.copyWith(
        reels: state.reels.where((r) => r.id != reelId).toList(),
      ));
    }
  }

  Future<void> updateDescription(int reelId, String description) async {
    final res = await repository.updateReel(reelId, description);
    if (res.isSuccess) {
      emit(state.copyWith(
        reels: state.reels
            .map((r) => r.id == reelId ? r.copyWith(description: description) : r)
            .toList(),
      ));
    }
  }

  /// Optimistic Facebook-style reaction toggle (mirrors ReelsFeedBloc); reverts
  /// on failure. [type] is one of like/love/haha/wow/sad/angry; sending the
  /// current type again clears it.
  Future<void> react(RealEntity reel, String type) async {
    final snapshot = state.reels;
    final updated = snapshot.map((r) {
      if (r.id != reel.id) return r;
      final prev = r.myReaction;
      final next = (prev == type) ? null : type;
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

    final res = await repository.reactReel(reel.id, type);
    if (res.isFailure) {
      emit(state.copyWith(reels: snapshot));
    }
  }

  /// Keep a reel's comment counter in step with the comments sheet (delta is +1
  /// for an add, negative for a delete).
  void adjustCommentCount(int reelId, int delta) {
    emit(state.copyWith(
      reels: state.reels
          .map((r) => r.id == reelId
              ? r.copyWith(commentsCount: (r.commentsCount + delta).clamp(0, 1 << 30))
              : r)
          .toList(),
    ));
  }
}
