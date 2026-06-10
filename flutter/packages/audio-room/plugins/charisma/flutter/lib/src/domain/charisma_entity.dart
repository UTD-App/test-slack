import 'package:equatable/equatable.dart';

class CharismaEntity extends Equatable {
  final int userId;
  final String total;
  final int position;

  const CharismaEntity({
    required this.userId,
    required this.total,
    required this.position,
  });

  @override
  List<Object?> get props => [userId];
}
