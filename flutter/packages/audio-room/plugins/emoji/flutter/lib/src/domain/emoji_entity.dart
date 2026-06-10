import 'package:equatable/equatable.dart';

class EmojiEntity extends Equatable {
  final int id;
  final int pid;
  final String? name;
  final String emoji;
  final int tLength;
  final int sort;
  final String? type;

  const EmojiEntity({
    required this.id,
    this.pid = 0,
    this.name,
    required this.emoji,
    this.tLength = 0,
    this.sort = 0,
    this.type,
  });

  @override
  List<Object?> get props => [id];
}
