import 'dart:io';

import 'package:utd_app/network/models/api_response.dart';

import '../entities/moment_comment_entity.dart';
import '../entities/moment_entity.dart';
import '../entities/moment_like_entity.dart';

/// Moment data operations. Implementations wrap the API and return [Result].
abstract class MomentRepository {
  /// type: 1=mine, 4=all, 5=new, 6=followed (backend maps these).
  Future<Result<List<MomentEntity>>> fetchMoments({
    int type = 4,
    int page = 1,
    int? userId,
  });

  /// The last-cached first page for instant/offline first paint. Returns an
  /// empty list when nothing has been cached yet. Never hits the network.
  Future<List<MomentEntity>> cachedMoments({int type = 4, int? userId});

  Future<Result<bool>> addMoment({required String text, List<File> images});

  Future<Result<bool>> deleteMoment(int momentId);

  /// Toggle like; returns the new isLike state is handled optimistically by the bloc.
  Future<Result<bool>> likeMoment(int momentId);

  /// Set a Facebook-style reaction (like/love/haha/wow/sad/angry); same type
  /// again toggles it off (server-side).
  Future<Result<bool>> reactMoment(int momentId, String reactionType);

  Future<Result<List<MomentLikeEntity>>> fetchLikes(int momentId, {int page = 1});

  Future<Result<List<MomentCommentEntity>>> fetchComments(int momentId, {int page = 1});

  Future<Result<bool>> addComment(int momentId, String comment, {int? parentId});

  Future<Result<bool>> deleteComment(int momentId, int commentId);

  /// Set a Facebook-style reaction on a comment; same type again toggles it off.
  Future<Result<bool>> reactComment(int momentId, int commentId, String reactionType);

  Future<Result<bool>> reportMoment(int momentId, {required String description, required String type});

  Future<Result<bool>> reportComment(int momentId, int commentId, {required String description, required String type});
}
