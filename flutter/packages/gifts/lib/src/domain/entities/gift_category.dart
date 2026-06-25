import 'package:equatable/equatable.dart';

/// A gift category (tab in the picker).
class GiftCategory extends Equatable {
  final int id;
  final String title;
  final String type;

  const GiftCategory({
    required this.id,
    required this.title,
    required this.type,
  });

  @override
  List<Object?> get props => [id];
}
