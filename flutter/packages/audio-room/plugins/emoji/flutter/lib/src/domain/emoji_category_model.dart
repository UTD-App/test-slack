import 'package:equatable/equatable.dart';

class EmojiCategoryModel extends Equatable {
  final int id;
  final String title;
  final String? type;
  final int sort;

  const EmojiCategoryModel({
    required this.id,
    required this.title,
    this.type,
    this.sort = 0,
  });

  factory EmojiCategoryModel.fromJson(Map<String, dynamic> json) {
    final titleRaw = json['title'];
    String title;
    if (titleRaw is Map) {
      title = (titleRaw['en'] ?? titleRaw['ar'] ?? titleRaw.values.first ?? '')
          .toString();
    } else {
      title = titleRaw?.toString() ?? '';
    }

    return EmojiCategoryModel(
      id: json['id'] as int,
      title: title,
      type: json['type'] as String?,
      sort: (json['sort'] as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props => [id];
}
