import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/core/base_use_case.dart';

import 'package:utd_app/shared/entities/my_data_entity.dart';
import '../params/information_parameter.dart';
import '../repositories/auth_repository.dart';

class AddInfoUseCase
    extends UseCase<BaseResponse<MyDataEntity>, InformationParameter> {
  final AuthRepository _repository;

  AddInfoUseCase(this._repository);

  @override
  Future<Result<BaseResponse<MyDataEntity>>> call(InformationParameter params) {
    return _repository.addInfo(params: params);
  }
}
