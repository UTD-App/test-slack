import 'package:utd_app/network/services/base_api_service.dart';

class SuperBombApiService extends BaseApiService {
  String levelsPath(int roomId) => '/boom_levels/$roomId';
  String videosPath() => '/boom_levels/get_videos';
  String themesPath() => '/room-boom/themes';
  String rulesPath() => '/super-boom-rules';
}
