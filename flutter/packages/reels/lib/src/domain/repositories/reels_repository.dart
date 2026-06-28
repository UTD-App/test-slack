import 'dart:io';

import 'package:utd_app/network/models/api_response.dart';

import '../entities/real_comment_entity.dart';
import '../entities/real_entity.dart';
import '../entities/real_like_entity.dart';

/// Reel data operations. Implementations wrap the API and return [Result].
abstract class ReelsRepository {
  Future<Result<List<RealEntity>>> fetchReels({int page = 1, String? filter, int? seed});

  Future<Result<List<RealEntity>>> fetchUserReals(int userId);

  Future<Result<List<RealEntity>>> fetchMyReals();

  Future<Result<List<RealEntity>>> fetchFollowersReels();

  Future<Result<bool>> addReel({
    required File video,
    String description,
    List<int> categories,
  });

  Future<Result<bool>> deleteReel(int reelId);

  /// Edit the caption/description of an existing reel.
  Future<Result<bool>> updateReel(int reelId, String description);

  /// Toggle like; the new isLike state is handled optimistically by the bloc.
  Future<Result<bool>> likeReel(int reelId);

  /// Set a Facebook-style reaction on a reel (same type again toggles it off).
  Future<Result<bool>> reactReel(int reelId, String reactionType);

  Future<Result<List<RealLikeEntity>>> fetchLikes(int reelId, {int page = 1});

  Future<Result<List<RealCommentEntity>>> fetchComments(int reelId, {int page = 1});

  Future<Result<bool>> addComment(int reelId, String comment, {int? parentId});

  Future<Result<bool>> deleteComment(int reelId, int commentId);

  /// Set a Facebook-style reaction on a comment (same type again toggles it off).
  Future<Result<bool>> reactComment(int reelId, int commentId, String reactionType);

  Future<Result<bool>> reportComment(int reelId, int commentId, {required String description, required String type});

  Future<Result<bool>> reportReel(int reelId, {required String description, required String type});

  Future<Result<bool>> recordView(int reelId, {int duration});
}
