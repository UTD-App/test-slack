import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import 'free_games_model.dart';

abstract class FreeGamesRepository {
  Future<Result<BaseResponse<FreeGamesModel>>> getImages();
}

abstract class FreeGamesRemoteDataSource {
  Future<Result<BaseResponse<FreeGamesModel>>> getImages();
}

class FreeGamesRepositoryImpl implements FreeGamesRepository {
  final FreeGamesRemoteDataSource remoteDataSource;

  FreeGamesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<BaseResponse<FreeGamesModel>>> getImages() =>
      remoteDataSource.getImages();
}
