import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../domain/charisma_level_model.dart';
import '../domain/charisma_model.dart';
import '../domain/charisma_repository.dart';
import 'charisma_api_service.dart';

class CharismaRemoteDataSourceImpl implements CharismaRemoteDataSource {
  final CharismaApiService apiService;

  CharismaRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Result<BaseResponse<List<CharismaLevelModel>>>>
      getCharismaLevels() async {
    return apiService.get(
      apiService.levelsPath(),
      fromJson: (json) => BaseResponse<List<CharismaLevelModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) =>
                CharismaLevelModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<List<CharismaModel>>>> getRoomCharisma(
      int roomId) async {
    return apiService.get(
      apiService.roomCharismaPath(roomId),
      fromJson: (json) => BaseResponse<List<CharismaModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => CharismaModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> getStatus(int roomId) async {
    return apiService.get(
      apiService.statusPath(roomId),
      fromJson: (json) => BaseResponse<Map<String, dynamic>>.fromJson(
        json,
        fromJsonT: (data) => data as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<Result<BaseResponse>> changeStatus(int roomId, {required bool status}) async {
    return apiService.post(
      apiService.changeStatusPath(),
      data: {'room_id': roomId, 'status': status},
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse>> resetCharisma(int roomId) async {
    return apiService.post(
      apiService.resetPath(),
      data: {'room_id': roomId},
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }
}
