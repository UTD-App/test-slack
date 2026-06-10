import 'package:equatable/equatable.dart';

class RoomCupRewardModel extends Equatable {
  final int id;
  final int roomCupTargetId;
  final String type;
  final String target;
  final int expire;

  const RoomCupRewardModel({
    required this.id,
    required this.roomCupTargetId,
    required this.type,
    required this.target,
    required this.expire,
  });

  factory RoomCupRewardModel.fromJson(Map<String, dynamic> json) {
    return RoomCupRewardModel(
      id: json['id'] as int,
      roomCupTargetId: (json['room_cup_target_id'] as int?) ?? 0,
      type: json['type'] as String? ?? '',
      target: json['target'] as String? ?? '',
      expire: (json['expire'] as int?) ?? 1,
    );
  }

  @override
  List<Object?> get props => [id];
}
