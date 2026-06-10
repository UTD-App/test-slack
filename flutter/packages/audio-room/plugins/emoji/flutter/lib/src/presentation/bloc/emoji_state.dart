part of 'emoji_bloc.dart';

class EmojiState extends Equatable {
  final List<EmojiCategoryModel> categories;
  final Map<int, List<EmojiModel>> categoryEmojis;
  final Map<int, RequestState> categoryReqStates;
  final RequestState categoriesState;
  final int? categoryId;
  final String? message;

  const EmojiState({
    this.categories = const [],
    this.categoryEmojis = const {},
    this.categoryReqStates = const {},
    this.categoriesState = RequestState.idle,
    this.categoryId,
    this.message,
  });

  EmojiState copyWith({
    List<EmojiCategoryModel>? categories,
    Map<int, List<EmojiModel>>? categoryEmojis,
    Map<int, RequestState>? categoryReqStates,
    RequestState? categoriesState,
    int? categoryId,
    String? message,
  }) {
    return EmojiState(
      categories: categories ?? this.categories,
      categoryEmojis: categoryEmojis ?? this.categoryEmojis,
      categoryReqStates: categoryReqStates ?? this.categoryReqStates,
      categoriesState: categoriesState ?? this.categoriesState,
      categoryId: categoryId ?? this.categoryId,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        categoryEmojis,
        categoryReqStates,
        categoriesState,
        categoryId,
        message,
      ];
}
