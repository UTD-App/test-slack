import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/core/base_use_case.dart';

import '../repositories/auth_repository.dart';

class CheckEmailUseCase extends UseCase<BaseResponse<bool>, String> {
  final AuthRepository _repository;

  CheckEmailUseCase(this._repository);

  @override
  Future<Result<BaseResponse<bool>>> call(String params) {
    return _repository.checkEmail(params);
  }
}
