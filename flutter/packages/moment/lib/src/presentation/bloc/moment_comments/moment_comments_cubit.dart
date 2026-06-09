import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/moment_comment_entity.dart';
import '../../../domain/repositories/moment_repository.dart';

enum CommentsStatus { initial, loading, success, failure }

class MomentCommentsState extends Equatable {
  final CommentsStatus status;
  final List<MomentCommentEntity> comments;
  final bool isSubmitting;
  final String? error;

  const MomentCommentsState({
    this.status = CommentsStatus.initial,
    this.comments = const [],
    this.isSubmitting = false,
    this.error,
  });

  MomentCommentsState copyWith({
    CommentsStatus? status,
    List<MomentCommentEntity>? comments,
    bool? isSubmitting,
    String? error,
  }) =>
      MomentCommentsState(
        status: status ?? this.status,
        comments: comments ?? this.comments,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
      );

  @override
  List<Object?> get props => [status, comments, isSubmitting, error];
}

class MomentCommentsCubit extends Cubit<MomentCommentsState> {
  final MomentRepository repository;
  final int momentId;

  MomentCommentsCubit(this.repository, this.momentId) : super(const MomentCommentsState());

  Future<void> load() async {
    emit(state.copyWith(status: CommentsStatus.loading, error: null));
    final res = await repository.fetchComments(momentId);
    res.when(
      success: (list) => emit(state.copyWith(status: CommentsStatus.success, comments: list)),
      failure: (msg, _) => emit(state.copyWith(status: CommentsStatus.failure, error: msg)),
    );
  }

  Future<bool> add(String text) async {
    if (text.trim().isEmpty) return false;
    emit(state.copyWith(isSubmitting: true));
    final res = await repository.addComment(momentId, text.trim());
    emit(state.copyWith(isSubmitting: false));
    if (res.isSuccess) {
      await load();
      return true;
    }
    return false;
  }
}
