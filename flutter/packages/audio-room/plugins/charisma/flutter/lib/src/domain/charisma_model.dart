import 'charisma_entity.dart';

class CharismaModel extends CharismaEntity {
  const CharismaModel({
    required super.userId,
    required super.total,
    required super.position,
  });

  factory CharismaModel.fromJson(Map<String, dynamic> json) {
    return CharismaModel(
      userId: json['user_id'] as int,
      total: (json['total'] ?? '0').toString(),
      position: (json['position'] as int?) ?? 0,
    );
  }
}
