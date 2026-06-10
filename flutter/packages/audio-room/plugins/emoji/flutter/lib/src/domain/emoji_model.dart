import 'emoji_entity.dart';

class EmojiModel extends EmojiEntity {
  const EmojiModel({
    required super.id,
    super.pid,
    super.name,
    required super.emoji,
    super.tLength,
    super.sort,
    super.type,
  });

  factory EmojiModel.fromJson(Map<String, dynamic> json) {
    return EmojiModel(
      id: json['id'] as int,
      pid: (json['pid'] as int?) ?? 0,
      name: json['name'] as String?,
      emoji: json['emoji'] as String? ?? '',
      tLength: (json['t_length'] as int?) ?? 0,
      sort: (json['sort'] as int?) ?? 0,
      type: json['image_type'] as String?,
    );
  }
}
