import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../domain/room_cup_repository.dart';
import 'room_cup_api_service.dart';

class RoomCupRemoteDataSourceImpl implements RoomCupRemoteDataSource {
  final RoomCupApiService apiService;

  RoomCupRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Result<BaseResponse>> getMyReward(int roomId) async {
    return apiService.get(
      apiService.myRewardPath(roomId),
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse>> getHistory(int roomId) async {
    return apiService.get(
      apiService.historyPath(roomId),
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse>> getCupTargets() async {
    return apiService.get(
      apiService.cupTargetPath(),
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }
}
