import 'package:equatable/equatable.dart';

class RoomCategoryEntity extends Equatable {
  final int id;
  final int? parentId;
  final String name;
  final String? nameEn;
  final String? image;
  final bool isEnabled;
  final List<RoomCategoryEntity> children;

  const RoomCategoryEntity({
    required this.id,
    this.parentId,
    required this.name,
    this.nameEn,
    this.image,
    this.isEnabled = true,
    this.children = const [],
  });

  @override
  List<Object?> get props => [id];
}
