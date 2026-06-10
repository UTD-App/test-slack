import 'package:equatable/equatable.dart';

import 'room_cup_reward_model.dart';

class RoomCupTargetModel extends Equatable {
  final int id;
  final String? title;
  final int targetValue;
  final String period;
  final bool isActive;
  final List<RoomCupRewardModel> rewards;

  const RoomCupTargetModel({
    required this.id,
    this.title,
    required this.targetValue,
    required this.period,
    required this.isActive,
    this.rewards = const [],
  });

  factory RoomCupTargetModel.fromJson(Map<String, dynamic> json) {
    return RoomCupTargetModel(
      id: json['id'] as int,
      title: json['title'] as String?,
      targetValue: (json['target_value'] as int?) ?? 0,
      period: json['period'] as String? ?? 'daily',
      isActive: json['is_active'] as bool? ?? true,
      rewards: (json['rewards'] as List?)
              ?.map((e) =>
                  RoomCupRewardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id];
}
