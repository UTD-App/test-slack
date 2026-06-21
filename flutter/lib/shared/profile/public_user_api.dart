import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/network/services/base_api_service.dart';

import 'public_user.dart';

/// Fetches a single user's public profile data from the always-available base
/// endpoint `GET /users/{id}`. Used by [VisitedProfileFallback] so visiting
/// another user works even when the rich Profile package isn't installed.
class PublicUserApi extends BaseApiService {
  Future<Result<PublicUser>> fetch(int userId) {
    return get<PublicUser>(
      '/users/$userId',
      fromJson: (json) => PublicUser.fromJson(
        ((json as Map)['data'] as Map).cast<String, dynamic>(),
      ),
    );
  }
}
