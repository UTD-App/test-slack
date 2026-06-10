import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import 'boom_level_model.dart';
import 'boom_rule_model.dart';
import 'boom_theme_model.dart';

abstract class SuperBombRepository {
  Future<Result<BaseResponse<List<BoomLevelModel>>>> getLevels(int roomId);
  Future<Result<BaseResponse<List<BoomLevelModel>>>> getVideos();
  Future<Result<BaseResponse<BoomThemeModel>>> getThemes();
  Future<Result<BaseResponse<List<BoomRuleModel>>>> getRules();
}

abstract class SuperBombRemoteDataSource {
  Future<Result<BaseResponse<List<BoomLevelModel>>>> getLevels(int roomId);
  Future<Result<BaseResponse<List<BoomLevelModel>>>> getVideos();
  Future<Result<BaseResponse<BoomThemeModel>>> getThemes();
  Future<Result<BaseResponse<List<BoomRuleModel>>>> getRules();
}

class SuperBombRepositoryImpl implements SuperBombRepository {
  final SuperBombRemoteDataSource remoteDataSource;

  SuperBombRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<BaseResponse<List<BoomLevelModel>>>> getLevels(int roomId) =>
      remoteDataSource.getLevels(roomId);

  @override
  Future<Result<BaseResponse<List<BoomLevelModel>>>> getVideos() =>
      remoteDataSource.getVideos();

  @override
  Future<Result<BaseResponse<BoomThemeModel>>> getThemes() =>
      remoteDataSource.getThemes();

  @override
  Future<Result<BaseResponse<List<BoomRuleModel>>>> getRules() =>
      remoteDataSource.getRules();
}
