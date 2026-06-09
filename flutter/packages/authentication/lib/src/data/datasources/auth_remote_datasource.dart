import 'package:authentication/src/data/models/login_model.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/models/my_data_model.dart';

import '../../domain/params/auth_parameter.dart';
import '../../domain/params/forget_password_parameter.dart';
import '../../domain/params/information_parameter.dart';
import '../../domain/params/register_parameter.dart';
import 'auth_api_service.dart';

abstract class AuthRemoteDataSource {
  Future<Result<BaseResponse<LoginModel>>> login(
    AuthParameter params,
  );

  Future<Result<BaseResponse<bool>>> checkEmail(String email);

  Future<Result<BaseResponse<String>>> register({
    required RegisterParameter params,
  });

  Future<Result<BaseResponse<String>>> forgetPassword({
    required ForgetPasswordParameter params,
  });

  Future<Result<BaseResponse<MyDataModel>>> addInfo({
    required InformationParameter params,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthApiService apiService;

  AuthRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Result<BaseResponse<LoginModel>>> login(
    AuthParameter params,
  ) async {
    final body = {
      'type': 'email_pass',
      'email': params.email,
      'password': params.password,
    };
    return apiService.post(
      apiService.loginPath,
      data: body,
      fromJson: (json) => BaseResponse<LoginModel>.fromJson(
        json,
        fromJsonT: (data) => LoginModel.fromJson(data),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<bool>>> checkEmail(String email) async {
    final body = {'email': email};
    return apiService.post(
      apiService.checkEmailPath,
      data: body,
      fromJson: (json) =>
          BaseResponse<bool>.fromJson(json, fromJsonT: (data) => data),
    );
  }

  @override
  Future<Result<BaseResponse<String>>> register({
    required RegisterParameter params,
  }) async {
    return apiService.post(
      apiService.registerPath,
      data: {
        'email': params.email,
        'password': params.password,
      },
      fromJson: (json) => BaseResponse<String>.fromJson(
        json,
        fromJsonT: (data) => data['auth_token'] as String,
      ),
    );
  }

  @override
  Future<Result<BaseResponse<String>>> forgetPassword({
    required ForgetPasswordParameter params,
  }) async {
    return apiService.post(
      apiService.resetPasswordPath,
      data: {
        'email': params.email,
        'token': params.token,
        'password': params.password,
      },
      fromJson: (json) => BaseResponse<String>.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse<MyDataModel>>> addInfo({
    required InformationParameter params,
  }) async {
    final Map<String, dynamic> data = {};

    if (params.isUpdateOnlyUid == true) {
      if (params.uuid?.isNotEmpty == true) data['uuid'] = params.uuid;
    } else {
      data['bio'] = params.bio;
      data['name'] = params.name;
      data['birthday'] = params.date;
      data['gender'] = params.gender ?? 1;
      data['old_multi_image'] = (params.oldMultiImages ?? []).join(',');
      if (params.uuid?.isNotEmpty == true) data['uuid'] = params.uuid;
    }

    return apiService.post(
      apiService.addInfoPath,
      data: data,
      fromJson: (json) => BaseResponse<MyDataModel>.fromJson(
        json,
        fromJsonT: (data) => MyDataModel.fromJson(data),
      ),
    );
  }
}
