part of 'emoji_bloc.dart';

sealed class EmojiEvent extends Equatable {
  const EmojiEvent();

  @override
  List<Object?> get props => [];
}

final class LoadEmojiCategoriesEvent extends EmojiEvent {
  const LoadEmojiCategoriesEvent();
}

final class LoadEmojisByCategoryEvent extends EmojiEvent {
  final int categoryId;

  const LoadEmojisByCategoryEvent({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

final class SetEmojiCategoryIdEvent extends EmojiEvent {
  final int? categoryId;

  const SetEmojiCategoryIdEvent({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}
