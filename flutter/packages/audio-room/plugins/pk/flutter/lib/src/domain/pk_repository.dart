import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import 'pk_model.dart';

abstract class PkRepository {
  Future<Result<BaseResponse<Map<String, dynamic>>>> showPk(
      {int? roomId, int? ownerId});
  Future<Result<BaseResponse<Map<String, dynamic>>>> startPk(
      {int? roomId, int? ownerId, required int minutes});
  Future<Result<BaseResponse<Map<String, dynamic>>>> closePk(
      {required int pkId, int? roomId, int? ownerId});
  Future<Result<BaseResponse<Map<String, dynamic>>>> hidePk(
      {int? roomId, int? ownerId});
  Future<Result<BaseResponse<List<PkHistoryModel>>>> getHistory(int roomId);
}

abstract class PkRemoteDataSource {
  Future<Result<BaseResponse<Map<String, dynamic>>>> showPk(
      {int? roomId, int? ownerId});
  Future<Result<BaseResponse<Map<String, dynamic>>>> startPk(
      {int? roomId, int? ownerId, required int minutes});
  Future<Result<BaseResponse<Map<String, dynamic>>>> closePk(
      {required int pkId, int? roomId, int? ownerId});
  Future<Result<BaseResponse<Map<String, dynamic>>>> hidePk(
      {int? roomId, int? ownerId});
  Future<Result<BaseResponse<List<PkHistoryModel>>>> getHistory(int roomId);
}

class PkRepositoryImpl implements PkRepository {
  final PkRemoteDataSource remoteDataSource;

  PkRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> showPk(
          {int? roomId, int? ownerId}) =>
      remoteDataSource.showPk(roomId: roomId, ownerId: ownerId);

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> startPk(
          {int? roomId, int? ownerId, required int minutes}) =>
      remoteDataSource.startPk(
          roomId: roomId, ownerId: ownerId, minutes: minutes);

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> closePk(
          {required int pkId, int? roomId, int? ownerId}) =>
      remoteDataSource.closePk(
          pkId: pkId, roomId: roomId, ownerId: ownerId);

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> hidePk(
          {int? roomId, int? ownerId}) =>
      remoteDataSource.hidePk(roomId: roomId, ownerId: ownerId);

  @override
  Future<Result<BaseResponse<List<PkHistoryModel>>>> getHistory(int roomId) =>
      remoteDataSource.getHistory(roomId);
}
