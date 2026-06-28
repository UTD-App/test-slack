import 'dart:io';

import 'package:dio/dio.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/network/services/base_api_service.dart';

import '../models/real_comment_model.dart';
import '../models/real_like_model.dart';
import '../models/real_model.dart';

/// Talks to the backend `utd/reels` package endpoints.
///
/// Backend wraps every response as `{ status, message, data }`. The helpers
/// below unwrap `data` / `status` from that envelope.
class ReelsApiService extends BaseApiService {
  static List<Map<String, dynamic>> _list(dynamic body) {
    final data = body is Map ? body['data'] : body;
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  static bool _status(dynamic body) {
    if (body is Map) {
      final s = body['status'];
      return s == true || s == 1 || s == '1';
    }
    return true;
  }

  /// The main reels feed. `filter` maps to the backend `filter` query (e.g. 'following').
  /// `seed` drives a stable per-refresh random order on the backend.
  Future<Result<List<RealModel>>> fetchReels({int page = 1, String? filter, int? seed}) {
    return get<List<RealModel>>(
      '/reals',
      queryParameters: {
        'page': page,
        if (filter != null) 'filter': filter,
        if (seed != null) 'seed': seed,
      },
      fromJson: (body) => _list(body).map(RealModel.fromJson).toList(),
    );
  }

  Future<Result<List<RealModel>>> fetchUserReals(int userId) {
    return get<List<RealModel>>(
      '/reals/user/$userId',
      fromJson: (body) => _list(body).map(RealModel.fromJson).toList(),
    );
  }

  Future<Result<List<RealModel>>> fetchMyReals() {
    return get<List<RealModel>>(
      '/reals/my-reals',
      fromJson: (body) => _list(body).map(RealModel.fromJson).toList(),
    );
  }

  Future<Result<List<RealModel>>> fetchFollowersReels() {
    return get<List<RealModel>>(
      '/reals/user-followers',
      fromJson: (body) => _list(body).map(RealModel.fromJson).toList(),
    );
  }

  Future<Result<bool>> addReel({
    required File video,
    String description = '',
    List<int> categories = const [],
  }) async {
    final form = FormData();
    form.fields.add(MapEntry('description', description));
    for (final c in categories) {
      form.fields.add(MapEntry('categories[]', '$c'));
    }
    form.files.add(MapEntry('video', await MultipartFile.fromFile(video.path)));
    return post<bool>('/reals', data: form, fromJson: _status);
  }

  Future<Result<bool>> deleteReel(int reelId) {
    return delete<bool>('/reals/$reelId', fromJson: _status);
  }

  /// Edit a reel's caption. Backend route is `POST /reals-update/{id}` (not the
  /// REST `/reals/{id}`) — see the utd/reels package routes.
  Future<Result<bool>> updateReel(int reelId, String description) {
    return post<bool>(
      '/reals-update/$reelId',
      data: {'description': description},
      fromJson: _status,
    );
  }

  Future<Result<bool>> likeReel(int reelId) {
    return post<bool>('/reals/$reelId/like', fromJson: _status);
  }

  /// Set a Facebook-style reaction on a reel. Same type again toggles it off
  /// (handled by the backend). Empty body would default to 'like'.
  Future<Result<bool>> reactReel(int reelId, String reactionType) {
    return post<bool>('/reals/$reelId/like', data: {'reaction_type': reactionType}, fromJson: _status);
  }

  Future<Result<List<RealLikeModel>>> fetchLikes(int reelId, {int page = 1}) {
    return get<List<RealLikeModel>>(
      '/reals/$reelId/like',
      queryParameters: {'page': page},
      fromJson: (body) => _list(body).map(RealLikeModel.fromJson).toList(),
    );
  }

  Future<Result<List<RealCommentModel>>> fetchComments(int reelId, {int page = 1}) {
    return get<List<RealCommentModel>>(
      '/reals/$reelId/comment',
      queryParameters: {'page': page},
      fromJson: (body) => _list(body).map(RealCommentModel.fromJson).toList(),
    );
  }

  Future<Result<bool>> addComment(int reelId, String comment, {int? parentId}) {
    return post<bool>(
      '/reals/$reelId/comment',
      data: {'comment': comment, if (parentId != null) 'parent_id': parentId},
      fromJson: _status,
    );
  }

  Future<Result<bool>> deleteComment(int reelId, int commentId) {
    return delete<bool>('/reals/$reelId/comment/$commentId', fromJson: _status);
  }

  /// Set a Facebook-style reaction on a comment (or reply). Same type again
  /// toggles it off (handled by the backend).
  Future<Result<bool>> reactComment(int reelId, int commentId, String reactionType) {
    return post<bool>(
      '/reals/$reelId/comment/$commentId/like',
      data: {'reaction_type': reactionType},
      fromJson: _status,
    );
  }

  Future<Result<bool>> reportComment(int reelId, int commentId, {required String description, required String type}) {
    return post<bool>(
      '/reals/$reelId/comment/$commentId/report',
      data: {'description': description, 'type': type},
      fromJson: _status,
    );
  }

  Future<Result<bool>> reportReel(int reelId, {required String description, required String type}) {
    return post<bool>(
      '/reals/$reelId/report',
      data: {'description': description, 'type': type},
      fromJson: _status,
    );
  }

  Future<Result<bool>> recordView(int reelId, {int duration = 0}) {
    return post<bool>('/reals/$reelId/view', data: {'duration': duration}, fromJson: _status);
  }
}
