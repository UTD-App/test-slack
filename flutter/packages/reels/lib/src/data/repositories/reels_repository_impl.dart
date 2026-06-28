import 'dart:io';

import 'package:utd_app/network/models/api_response.dart';

import '../../domain/entities/real_comment_entity.dart';
import '../../domain/entities/real_entity.dart';
import '../../domain/entities/real_like_entity.dart';
import '../../domain/repositories/reels_repository.dart';
import '../datasources/reels_api_service.dart';

class ReelsRepositoryImpl implements ReelsRepository {
  final ReelsApiService api;

  ReelsRepositoryImpl(this.api);

  @override
  Future<Result<List<RealEntity>>> fetchReels({int page = 1, String? filter, int? seed}) async {
    final res = await api.fetchReels(page: page, filter: filter, seed: seed);
    return res.map((list) => list.cast<RealEntity>());
  }

  @override
  Future<Result<List<RealEntity>>> fetchUserReals(int userId) async {
    final res = await api.fetchUserReals(userId);
    return res.map((list) => list.cast<RealEntity>());
  }

  @override
  Future<Result<List<RealEntity>>> fetchMyReals() async {
    final res = await api.fetchMyReals();
    return res.map((list) => list.cast<RealEntity>());
  }

  @override
  Future<Result<List<RealEntity>>> fetchFollowersReels() async {
    final res = await api.fetchFollowersReels();
    return res.map((list) => list.cast<RealEntity>());
  }

  @override
  Future<Result<bool>> addReel({
    required File video,
    String description = '',
    List<int> categories = const [],
  }) =>
      api.addReel(video: video, description: description, categories: categories);

  @override
  Future<Result<bool>> deleteReel(int reelId) => api.deleteReel(reelId);

  @override
  Future<Result<bool>> updateReel(int reelId, String description) =>
      api.updateReel(reelId, description);

  @override
  Future<Result<bool>> likeReel(int reelId) => api.likeReel(reelId);

  @override
  Future<Result<bool>> reactReel(int reelId, String reactionType) => api.reactReel(reelId, reactionType);

  @override
  Future<Result<List<RealLikeEntity>>> fetchLikes(int reelId, {int page = 1}) async {
    final res = await api.fetchLikes(reelId, page: page);
    return res.map((list) => list.cast<RealLikeEntity>());
  }

  @override
  Future<Result<List<RealCommentEntity>>> fetchComments(int reelId, {int page = 1}) async {
    final res = await api.fetchComments(reelId, page: page);
    return res.map((list) => list.cast<RealCommentEntity>());
  }

  @override
  Future<Result<bool>> addComment(int reelId, String comment, {int? parentId}) =>
      api.addComment(reelId, comment, parentId: parentId);

  @override
  Future<Result<bool>> deleteComment(int reelId, int commentId) => api.deleteComment(reelId, commentId);

  @override
  Future<Result<bool>> reactComment(int reelId, int commentId, String reactionType) =>
      api.reactComment(reelId, commentId, reactionType);

  @override
  Future<Result<bool>> reportComment(int reelId, int commentId, {required String description, required String type}) =>
      api.reportComment(reelId, commentId, description: description, type: type);

  @override
  Future<Result<bool>> reportReel(int reelId, {required String description, required String type}) =>
      api.reportReel(reelId, description: description, type: type);

  @override
  Future<Result<bool>> recordView(int reelId, {int duration = 0}) =>
      api.recordView(reelId, duration: duration);
}
