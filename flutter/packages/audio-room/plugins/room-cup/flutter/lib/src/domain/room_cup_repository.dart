import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

abstract class RoomCupRepository {
  Future<Result<BaseResponse>> getMyReward(int roomId);
  Future<Result<BaseResponse>> getHistory(int roomId);
  Future<Result<BaseResponse>> getCupTargets();
}

abstract class RoomCupRemoteDataSource {
  Future<Result<BaseResponse>> getMyReward(int roomId);
  Future<Result<BaseResponse>> getHistory(int roomId);
  Future<Result<BaseResponse>> getCupTargets();
}

class RoomCupRepositoryImpl implements RoomCupRepository {
  final RoomCupRemoteDataSource remoteDataSource;

  RoomCupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<BaseResponse>> getMyReward(int roomId) =>
      remoteDataSource.getMyReward(roomId);

  @override
  Future<Result<BaseResponse>> getHistory(int roomId) =>
      remoteDataSource.getHistory(roomId);

  @override
  Future<Result<BaseResponse>> getCupTargets() =>
      remoteDataSource.getCupTargets();
}
