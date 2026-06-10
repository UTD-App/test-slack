import 'package:utd_app/network/services/base_api_service.dart';

class RoomCupApiService extends BaseApiService {
  String myRewardPath(int roomId) => '/room-cup/report/$roomId';
  String historyPath(int roomId) => '/room-cup/history/$roomId';
  String cupTargetPath() => '/room-cup/cup-target';
}
