import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/moment_like_entity.dart';
import '../../../domain/repositories/moment_repository.dart';

enum LikesStatus { initial, loading, success, failure }

class MomentLikesState extends Equatable {
  final LikesStatus status;
  final List<MomentLikeEntity> likes;
  final String? error;

  const MomentLikesState({
    this.status = LikesStatus.initial,
    this.likes = const [],
    this.error,
  });

  MomentLikesState copyWith({
    LikesStatus? status,
    List<MomentLikeEntity>? likes,
    String? error,
  }) =>
      MomentLikesState(
        status: status ?? this.status,
        likes: likes ?? this.likes,
        error: error,
      );

  @override
  List<Object?> get props => [status, likes, error];
}

class MomentLikesCubit extends Cubit<MomentLikesState> {
  final MomentRepository repository;
  final int momentId;

  MomentLikesCubit(this.repository, this.momentId) : super(const MomentLikesState());

  Future<void> load() async {
    emit(state.copyWith(status: LikesStatus.loading, error: null));
    final res = await repository.fetchLikes(momentId);
    res.when(
      success: (list) => emit(state.copyWith(status: LikesStatus.success, likes: list)),
      failure: (msg, _) => emit(state.copyWith(status: LikesStatus.failure, error: msg)),
    );
  }
}
