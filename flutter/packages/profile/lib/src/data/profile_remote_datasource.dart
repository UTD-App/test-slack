import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../domain/user_profile_model.dart';
import 'profile_api_service.dart';

abstract class ProfileRemoteDataSource {
  Future<Result<BaseResponse<UserProfileModel>>> getUserProfile(int userId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ProfileApiService apiService;

  ProfileRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Result<BaseResponse<UserProfileModel>>> getUserProfile(
    int userId,
  ) async {
    return apiService.get(
      apiService.userProfilePath(userId),
      fromJson: (json) => BaseResponse<UserProfileModel>.fromJson(
        json,
        fromJsonT: (data) => UserProfileModel.fromJson(data),
      ),
    );
  }
}
