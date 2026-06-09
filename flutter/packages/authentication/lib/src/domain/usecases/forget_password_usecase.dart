import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/core/base_use_case.dart';

import '../params/forget_password_parameter.dart';
import '../repositories/auth_repository.dart';

class ForgetPasswordUseCase
    extends UseCase<BaseResponse<String>, ForgetPasswordParameter> {
  final AuthRepository _repository;

  ForgetPasswordUseCase(this._repository);

  @override
  Future<Result<BaseResponse<String>>> call(ForgetPasswordParameter params) {
    return _repository.forgetPassword(params: params);
  }
}
