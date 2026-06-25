import 'dart:io';

import 'package:utd_app/network/models/api_response.dart';

import '../../domain/entities/moment_comment_entity.dart';
import '../../domain/entities/moment_entity.dart';
import '../../domain/entities/moment_like_entity.dart';
import '../../domain/repositories/moment_repository.dart';
import '../datasources/moment_api_service.dart';

class MomentRepositoryImpl implements MomentRepository {
  final MomentApiService api;

  MomentRepositoryImpl(this.api);

  @override
  Future<Result<List<MomentEntity>>> fetchMoments({int type = 4, int page = 1, int? userId}) async {
    final res = await api.fetchMoments(type: type, page: page, userId: userId);
    return res.map((list) => list.cast<MomentEntity>());
  }

  @override
  Future<Result<bool>> addMoment({required String text, List<File> images = const []}) =>
      api.addMoment(text: text, images: images);

  @override
  Future<Result<bool>> deleteMoment(int momentId) => api.deleteMoment(momentId);

  @override
  Future<Result<bool>> likeMoment(int momentId) => api.likeMoment(momentId);

  @override
  Future<Result<bool>> reactMoment(int momentId, String reactionType) => api.reactMoment(momentId, reactionType);

  @override
  Future<Result<List<MomentLikeEntity>>> fetchLikes(int momentId, {int page = 1}) async {
    final res = await api.fetchLikes(momentId, page: page);
    return res.map((list) => list.cast<MomentLikeEntity>());
  }

  @override
  Future<Result<List<MomentCommentEntity>>> fetchComments(int momentId, {int page = 1}) async {
    final res = await api.fetchComments(momentId, page: page);
    return res.map((list) => list.cast<MomentCommentEntity>());
  }

  @override
  Future<Result<bool>> addComment(int momentId, String comment, {int? parentId}) =>
      api.addComment(momentId, comment, parentId: parentId);

  @override
  Future<Result<bool>> deleteComment(int momentId, int commentId) => api.deleteComment(momentId, commentId);

  @override
  Future<Result<bool>> reactComment(int momentId, int commentId, String reactionType) =>
      api.reactComment(momentId, commentId, reactionType);

  @override
  Future<Result<bool>> reportMoment(int momentId, {required String description, required String type}) =>
      api.reportMoment(momentId, description: description, type: type);

  @override
  Future<Result<bool>> reportComment(int momentId, int commentId, {required String description, required String type}) =>
      api.reportComment(momentId, commentId, description: description, type: type);
}
