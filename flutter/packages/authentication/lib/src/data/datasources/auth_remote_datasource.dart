import 'package:authentication/src/data/models/login_model.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/models/my_data_model.dart';

import '../../domain/params/auth_parameter.dart';
import '../../domain/params/forget_password_parameter.dart';
import '../../domain/params/information_parameter.dart';
import '../../domain/params/recover_otp_parameter.dart';
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

  // Email-OTP recovery.
  Future<Result<BaseResponse<String>>> sendOtp(String email);

  Future<Result<BaseResponse<String>>> verifyOtp(VerifyOtpParameter params);

  Future<Result<BaseResponse<String>>> resetWithOtp(ResetWithOtpParameter params);

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
  Future<Result<BaseResponse<String>>> sendOtp(String email) async {
    return apiService.post(
      apiService.sendOtpPath,
      data: {'email': email},
      fromJson: (json) => BaseResponse<String>.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse<String>>> verifyOtp(
    VerifyOtpParameter params,
  ) async {
    return apiService.post(
      apiService.verifyOtpPath,
      data: {'email': params.email, 'code': params.code},
      fromJson: (json) => BaseResponse<String>.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse<String>>> resetWithOtp(
    ResetWithOtpParameter params,
  ) async {
    return apiService.post(
      apiService.resetWithOtpPath,
      data: {
        'email': params.email,
        'code': params.code,
        'password': params.password,
      },
      fromJson: (json) => BaseResponse<String>.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse<MyDataModel>>> addInfo({
    required InformationParameter params,
  }) async {
    // String-valued fields (FormData requires strings; JSON tolerates them too).
    final Map<String, dynamic> fields = {};

    if (params.isUpdateOnlyUid == true) {
      if (params.uuid?.isNotEmpty == true) fields['uuid'] = params.uuid!;
    } else {
      if (params.bio != null) fields['bio'] = params.bio!;
      if (params.name != null) fields['name'] = params.name!;
      if (params.date != null) fields['birthday'] = params.date!;
      fields['gender'] = (params.gender ?? 1).toString();
      fields['old_multi_image'] = (params.oldMultiImages ?? []).join(',');
      if (params.uuid?.isNotEmpty == true) fields['uuid'] = params.uuid!;
    }

    fromJson(json) => BaseResponse<MyDataModel>.fromJson(
          json,
          fromJsonT: (data) => MyDataModel.fromJson(data),
        );

    // When a new avatar was picked, send the raw file as `avatar` (the field the
    // backend's updateProfile reads via $request->hasFile('avatar')) using a
    // multipart upload; otherwise a plain JSON post is enough.
    if (params.image != null) {
      return apiService.uploadFile(
        apiService.addInfoPath,
        filePath: params.image!.path,
        fieldName: 'avatar',
        additionalFields: fields,
        fromJson: fromJson,
      );
    }

    return apiService.post(
      apiService.addInfoPath,
      data: fields,
      fromJson: fromJson,
    );
  }
}
