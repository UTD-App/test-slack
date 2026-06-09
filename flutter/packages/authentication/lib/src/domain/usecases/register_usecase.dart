import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/core/base_use_case.dart';

import '../params/register_parameter.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase extends UseCase<BaseResponse<String>, RegisterParameter> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Result<BaseResponse<String>>> call(RegisterParameter params) {
    return _repository.register(params: params);
  }
}
