import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import 'charisma_level_model.dart';
import 'charisma_model.dart';

abstract class CharismaRepository {
  Future<Result<BaseResponse<List<CharismaLevelModel>>>> getCharismaLevels();
  Future<Result<BaseResponse<List<CharismaModel>>>> getRoomCharisma(int roomId);
  Future<Result<BaseResponse<Map<String, dynamic>>>> getStatus(int roomId);
  Future<Result<BaseResponse>> changeStatus(int roomId, {required bool status});
  Future<Result<BaseResponse>> resetCharisma(int roomId);
}

abstract class CharismaRemoteDataSource {
  Future<Result<BaseResponse<List<CharismaLevelModel>>>> getCharismaLevels();
  Future<Result<BaseResponse<List<CharismaModel>>>> getRoomCharisma(int roomId);
  Future<Result<BaseResponse<Map<String, dynamic>>>> getStatus(int roomId);
  Future<Result<BaseResponse>> changeStatus(int roomId, {required bool status});
  Future<Result<BaseResponse>> resetCharisma(int roomId);
}

class CharismaRepositoryImpl implements CharismaRepository {
  final CharismaRemoteDataSource remoteDataSource;

  CharismaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<BaseResponse<List<CharismaLevelModel>>>> getCharismaLevels() =>
      remoteDataSource.getCharismaLevels();

  @override
  Future<Result<BaseResponse<List<CharismaModel>>>> getRoomCharisma(
          int roomId) =>
      remoteDataSource.getRoomCharisma(roomId);

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> getStatus(int roomId) =>
      remoteDataSource.getStatus(roomId);

  @override
  Future<Result<BaseResponse>> changeStatus(int roomId, {required bool status}) =>
      remoteDataSource.changeStatus(roomId, status: status);

  @override
  Future<Result<BaseResponse>> resetCharisma(int roomId) =>
      remoteDataSource.resetCharisma(roomId);
}
