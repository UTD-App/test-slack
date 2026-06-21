import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/core/base_use_case.dart';

import '../params/recover_otp_parameter.dart';
import '../repositories/auth_repository.dart';

/// Step 3: set a new password using a verified WhatsApp OTP code.
class ResetWithOtpUseCase
    extends UseCase<BaseResponse<String>, ResetWithOtpParameter> {
  final AuthRepository _repository;

  ResetWithOtpUseCase(this._repository);

  @override
  Future<Result<BaseResponse<String>>> call(ResetWithOtpParameter params) {
    return _repository.resetWithOtp(params);
  }
}
