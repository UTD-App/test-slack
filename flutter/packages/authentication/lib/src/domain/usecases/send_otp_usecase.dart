import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/core/base_use_case.dart';

import '../repositories/auth_repository.dart';

/// Step 1: send a WhatsApp OTP to the given phone.
class SendOtpUseCase extends UseCase<BaseResponse<String>, String> {
  final AuthRepository _repository;

  SendOtpUseCase(this._repository);

  @override
  Future<Result<BaseResponse<String>>> call(String params) {
    return _repository.sendOtp(params);
  }
}
