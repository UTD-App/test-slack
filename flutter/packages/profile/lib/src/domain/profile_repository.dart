import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../data/profile_remote_datasource.dart';
import 'user_profile_model.dart';

abstract class ProfileRepository {
  Future<Result<BaseResponse<UserProfileModel>>> getUserProfile(int userId);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<BaseResponse<UserProfileModel>>> getUserProfile(int userId) {
    return remoteDataSource.getUserProfile(userId);
  }
}
