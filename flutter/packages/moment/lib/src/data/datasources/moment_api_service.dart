import 'dart:io';

import 'package:dio/dio.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/network/services/base_api_service.dart';

import '../models/moment_comment_model.dart';
import '../models/moment_like_model.dart';
import '../models/moment_model.dart';

/// Talks to the backend `utd/moment` package endpoints.
///
/// Backend wraps every response as `{ status, message, data }`. The helpers
/// below unwrap `data` / `status` from that envelope.
class MomentApiService extends BaseApiService {
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

  Future<Result<List<MomentModel>>> fetchMoments({
    int type = 4,
    int page = 1,
    int? userId,
  }) {
    return get<List<MomentModel>>(
      '/moment',
      queryParameters: {
        'type': type,
        'page': page,
        if (userId != null) 'user_id': userId,
      },
      fromJson: (body) => _list(body).map(MomentModel.fromJson).toList(),
    );
  }

  Future<Result<bool>> addMoment({required String text, List<File> images = const []}) async {
    final form = FormData();
    form.fields.add(MapEntry('contacts', text));
    for (final file in images) {
      form.files.add(MapEntry('multi_image[]', await MultipartFile.fromFile(file.path)));
    }
    return post<bool>('/moment', data: form, fromJson: _status);
  }

  Future<Result<bool>> deleteMoment(int momentId) {
    return delete<bool>('/moment/$momentId', fromJson: _status);
  }

  Future<Result<bool>> likeMoment(int momentId) {
    return post<bool>('/moment/$momentId/like', fromJson: _status);
  }

  Future<Result<List<MomentLikeModel>>> fetchLikes(int momentId, {int page = 1}) {
    return get<List<MomentLikeModel>>(
      '/moment/$momentId/like',
      queryParameters: {'page': page},
      fromJson: (body) => _list(body).map(MomentLikeModel.fromJson).toList(),
    );
  }

  Future<Result<List<MomentCommentModel>>> fetchComments(int momentId, {int page = 1}) {
    return get<List<MomentCommentModel>>(
      '/moment/$momentId/comment',
      queryParameters: {'page': page},
      fromJson: (body) => _list(body).map(MomentCommentModel.fromJson).toList(),
    );
  }

  Future<Result<bool>> addComment(int momentId, String comment) {
    return post<bool>('/moment/$momentId/comment', data: {'comment': comment}, fromJson: _status);
  }

  Future<Result<bool>> deleteComment(int momentId, int commentId) {
    return delete<bool>('/moment/$momentId/comment/$commentId', fromJson: _status);
  }

  Future<Result<bool>> reportMoment(int momentId, {required String description, required String type}) {
    return post<bool>(
      '/moment/$momentId/report',
      data: {'description': description, 'type': type},
      fromJson: _status,
    );
  }
}
