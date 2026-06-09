import 'package:authentication/src/domain/entities/login_entity.dart';
import 'package:utd_app/shared/models/my_data_model.dart';

class LoginModel extends LoginEntity {
  const LoginModel({
    required super.id,
    required super.isFirst,
    required super.authToken,
    super.user,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      id: json['id'] as int,
      isFirst: json['is_first'] as bool,
      authToken: json['auth_token'] as String,
      user: json['user'] != null
          ? MyDataModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
