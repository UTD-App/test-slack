import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/network/services/base_api_service.dart';

import 'search_user_model.dart';

/// Talks to the Base user-search API. Paths are relative to the configured API
/// base (which already includes the prefix) — same convention as the
/// notifications/social/profile services.
class SearchApiService extends BaseApiService {
  /// Find other users by UID (`uuid`) or name. A blank query returns an empty
  /// list (the backend treats it as idle, no error).
  Future<Result<List<SearchUser>>> searchUsers(String query) {
    return get<List<SearchUser>>(
      '/users/search',
      queryParameters: {'q': query},
      fromJson: (json) {
        final items = (json['data'] as List?) ?? const [];
        return items
            .map((e) => SearchUser.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      },
    );
  }
}
