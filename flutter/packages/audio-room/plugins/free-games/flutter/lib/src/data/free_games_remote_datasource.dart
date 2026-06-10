import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../domain/free_games_model.dart';
import '../domain/free_games_repository.dart';
import 'free_games_api_service.dart';

class FreeGamesRemoteDataSourceImpl implements FreeGamesRemoteDataSource {
  final FreeGamesApiService apiService;

  FreeGamesRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Result<BaseResponse<FreeGamesModel>>> getImages() async {
    return apiService.get(
      apiService.imagesPath(),
      fromJson: (json) => BaseResponse<FreeGamesModel>.fromJson(
        json,
        fromJsonT: (data) =>
            FreeGamesModel.fromJson(data as Map<String, dynamic>),
      ),
    );
  }
}
