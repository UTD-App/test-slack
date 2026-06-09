import 'package:authentication/src/domain/entities/login_entity.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';
import 'package:utd_app/shared/entities/my_data_entity.dart';

import '../../domain/params/auth_parameter.dart';
import '../../domain/params/forget_password_parameter.dart';
import '../../domain/params/information_parameter.dart';
import '../../domain/params/register_parameter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<BaseResponse<LoginEntity>>> login(
    AuthParameter params,
  ) {
    return remoteDataSource.login(params);
  }

  @override
  Future<Result<BaseResponse<bool>>> checkEmail(String email) {
    return remoteDataSource.checkEmail(email);
  }

  @override
  Future<Result<BaseResponse<String>>> register({
    required RegisterParameter params,
  }) {
    return remoteDataSource.register(params: params);
  }

  @override
  Future<Result<BaseResponse<String>>> forgetPassword({
    required ForgetPasswordParameter params,
  }) {
    return remoteDataSource.forgetPassword(params: params);
  }

  @override
  Future<Result<BaseResponse<MyDataEntity>>> addInfo({
    required InformationParameter params,
  }) {
    return remoteDataSource.addInfo(params: params);
  }
}
