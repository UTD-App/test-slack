import 'package:utd_app/network/services/base_api_service.dart';

class CharismaApiService extends BaseApiService {
  String levelsPath() => '/charisma/levels';
  String roomCharismaPath(int roomId) => '/charisma/room/$roomId';
  String statusPath(int roomId) => '/charisma/status/$roomId';
  String changeStatusPath() => '/charisma/change-status';
  String resetPath() => '/charisma/reset';
}
