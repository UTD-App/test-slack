import 'package:utd_app/network/services/base_api_service.dart';

class PkApiService extends BaseApiService {
  String showPkPath() => '/rooms/show-pk';
  String createPkPath() => '/rooms/create-pk';
  String closePkPath() => '/rooms/close-pk';
  String hidePkPath() => '/rooms/hide-pk';
  String historyPath(int roomId) => '/room-pk/$roomId';
}
