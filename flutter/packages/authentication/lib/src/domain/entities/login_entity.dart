import 'package:equatable/equatable.dart';
import 'package:utd_app/shared/entities/my_data_entity.dart';

class LoginEntity extends Equatable {
  final int id;
  final bool isFirst;
  final String authToken;
  final MyDataEntity? user;

  const LoginEntity({
    required this.id,
    required this.isFirst,
    required this.authToken,
    this.user,
  });

  @override
  List<Object?> get props => [id, isFirst, authToken, user];
}
