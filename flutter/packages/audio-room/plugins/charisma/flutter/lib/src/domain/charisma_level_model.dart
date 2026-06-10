import 'package:equatable/equatable.dart';

class CharismaLevelModel extends Equatable {
  final int level;
  final int points;
  final String image;

  const CharismaLevelModel({
    required this.level,
    required this.points,
    required this.image,
  });

  factory CharismaLevelModel.fromJson(Map<String, dynamic> json) {
    return CharismaLevelModel(
      level: json['level'] as int,
      points: (json['points'] as int?) ?? 0,
      image: json['image'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [level];
}
