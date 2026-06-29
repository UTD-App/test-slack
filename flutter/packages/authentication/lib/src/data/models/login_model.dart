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
    // Defensive coercion: a malformed/edge login response (id as String/num,
    // is_first as 0/1, missing auth_token, non-map user) must fail cleanly into
    // safe defaults instead of throwing an uncaught cast error.
    return LoginModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      isFirst: _asBool(json['is_first']),
      authToken: json['auth_token']?.toString() ?? '',
      user: json['user'] is Map
          ? MyDataModel.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
    );
  }

  /// Accepts bool, 0/1 ints, and "true"/"1" strings → bool.
  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }
}
