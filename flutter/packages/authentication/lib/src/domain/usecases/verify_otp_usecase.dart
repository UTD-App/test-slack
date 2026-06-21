import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/core/base_use_case.dart';

import '../params/recover_otp_parameter.dart';
import '../repositories/auth_repository.dart';

/// Step 2: verify a WhatsApp OTP code without consuming it.
class VerifyOtpUseCase extends UseCase<BaseResponse<String>, VerifyOtpParameter> {
  final AuthRepository _repository;

  VerifyOtpUseCase(this._repository);

  @override
  Future<Result<BaseResponse<String>>> call(VerifyOtpParameter params) {
    return _repository.verifyOtp(params);
  }
}
