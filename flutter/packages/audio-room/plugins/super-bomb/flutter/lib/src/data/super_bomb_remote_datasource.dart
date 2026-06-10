import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../domain/boom_level_model.dart';
import '../domain/boom_rule_model.dart';
import '../domain/boom_theme_model.dart';
import '../domain/super_bomb_repository.dart';
import 'super_bomb_api_service.dart';

class SuperBombRemoteDataSourceImpl implements SuperBombRemoteDataSource {
  final SuperBombApiService apiService;

  SuperBombRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Result<BaseResponse<List<BoomLevelModel>>>> getLevels(
      int roomId) async {
    return apiService.get(
      apiService.levelsPath(roomId),
      fromJson: (json) => BaseResponse<List<BoomLevelModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => BoomLevelModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<List<BoomLevelModel>>>> getVideos() async {
    return apiService.get(
      apiService.videosPath(),
      fromJson: (json) => BaseResponse<List<BoomLevelModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => BoomLevelModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<BoomThemeModel>>> getThemes() async {
    return apiService.get(
      apiService.themesPath(),
      fromJson: (json) => BaseResponse<BoomThemeModel>.fromJson(
        json,
        fromJsonT: (data) =>
            BoomThemeModel.fromJson(data as Map<String, dynamic>),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<List<BoomRuleModel>>>> getRules() async {
    return apiService.get(
      apiService.rulesPath(),
      fromJson: (json) => BaseResponse<List<BoomRuleModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => BoomRuleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }
}
