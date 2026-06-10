import 'package:equatable/equatable.dart';

class FreeGameModel extends Equatable {
  final int id;
  final String image;

  const FreeGameModel({
    required this.id,
    required this.image,
  });

  factory FreeGameModel.fromJson(Map<String, dynamic> json) {
    return FreeGameModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      image: json['image'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, image];
}

class FreeGamesModel extends Equatable {
  final FreeGameModel dice;
  final FreeGameModel rps;
  final FreeGameModel giftBox;

  const FreeGamesModel({
    required this.dice,
    required this.rps,
    required this.giftBox,
  });

  factory FreeGamesModel.fromJson(Map<String, dynamic> json) {
    return FreeGamesModel(
      dice: FreeGameModel.fromJson(
          json['dice'] as Map<String, dynamic>? ?? {}),
      rps: FreeGameModel.fromJson(
          json['rps'] as Map<String, dynamic>? ?? {}),
      giftBox: FreeGameModel.fromJson(
          json['gift_box'] as Map<String, dynamic>? ?? {}),
    );
  }

  @override
  List<Object?> get props => [dice, rps, giftBox];
}
