import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../domain/pk_model.dart';
import '../domain/pk_repository.dart';
import 'pk_api_service.dart';

class PkRemoteDataSourceImpl implements PkRemoteDataSource {
  final PkApiService apiService;

  PkRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> showPk(
      {int? roomId, int? ownerId}) async {
    return apiService.post(
      apiService.showPkPath(),
      data: {
        if (roomId != null) 'room_id': roomId,
        if (ownerId != null) 'owner_id': ownerId,
      },
      fromJson: (json) => BaseResponse<Map<String, dynamic>>.fromJson(
        json,
        fromJsonT: (data) => data as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> startPk(
      {int? roomId, int? ownerId, required int minutes}) async {
    return apiService.post(
      apiService.createPkPath(),
      data: {
        if (roomId != null) 'room_id': roomId,
        if (ownerId != null) 'owner_id': ownerId,
        'minutes': minutes,
      },
      fromJson: (json) => BaseResponse<Map<String, dynamic>>.fromJson(
        json,
        fromJsonT: (data) => data as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> closePk(
      {required int pkId, int? roomId, int? ownerId}) async {
    return apiService.post(
      apiService.closePkPath(),
      data: {
        'pk_id': pkId,
        if (roomId != null) 'room_id': roomId,
        if (ownerId != null) 'owner_id': ownerId,
      },
      fromJson: (json) => BaseResponse<Map<String, dynamic>>.fromJson(
        json,
        fromJsonT: (data) => data as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> hidePk(
      {int? roomId, int? ownerId}) async {
    return apiService.post(
      apiService.hidePkPath(),
      data: {
        if (roomId != null) 'room_id': roomId,
        if (ownerId != null) 'owner_id': ownerId,
      },
      fromJson: (json) => BaseResponse<Map<String, dynamic>>.fromJson(
        json,
        fromJsonT: (data) => data as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<Result<BaseResponse<List<PkHistoryModel>>>> getHistory(
      int roomId) async {
    return apiService.get(
      apiService.historyPath(roomId),
      fromJson: (json) => BaseResponse<List<PkHistoryModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => PkHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }
}
