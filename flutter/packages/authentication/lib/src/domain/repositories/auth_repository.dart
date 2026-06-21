import 'package:authentication/src/domain/entities/login_entity.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import 'package:utd_app/shared/entities/my_data_entity.dart';
import '../params/auth_parameter.dart';
import '../params/forget_password_parameter.dart';
import '../params/information_parameter.dart';
import '../params/recover_otp_parameter.dart';
import '../params/register_parameter.dart';

abstract class AuthRepository {
  Future<Result<BaseResponse<LoginEntity>>> login(AuthParameter params);

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

  Future<Result<BaseResponse<MyDataEntity>>> addInfo({
    required InformationParameter params,
  });
}
