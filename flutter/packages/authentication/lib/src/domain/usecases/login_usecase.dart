import 'package:authentication/src/domain/entities/login_entity.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/core/base_use_case.dart';
import '../params/auth_parameter.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase extends UseCase<BaseResponse<LoginEntity>, AuthParameter> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Result<BaseResponse<LoginEntity>>> call(AuthParameter params) {
    return _repository.login(params);
  }
}
