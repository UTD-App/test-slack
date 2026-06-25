import 'package:equatable/equatable.dart';

/// A gift in the catalog.
class Gift extends Equatable {
  final int id;
  final String name;
  final int type;
  final int? categoryId;
  final int price; // coins
  final String img;
  final String showImg;
  final String imageType;
  final int vipLevel;

  const Gift({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryId,
    required this.price,
    required this.img,
    required this.showImg,
    required this.imageType,
    required this.vipLevel,
  });

  @override
  List<Object?> get props => [id];
}
