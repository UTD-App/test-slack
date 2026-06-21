import 'package:utd_app/network/services/base_api_service.dart';

class ProfileApiService extends BaseApiService {
  static const String _userProfile = '/users/{id}/profile';

  String userProfilePath(int userId) =>
      _userProfile.replaceFirst('{id}', userId.toString());
}
