import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/emoji_category_model.dart';
import '../../domain/emoji_model.dart';
import '../../domain/emoji_repository.dart';

part 'emoji_event.dart';
part 'emoji_state.dart';

class EmojiBloc extends Bloc<EmojiEvent, EmojiState> {
  final EmojiRepository repository;

  EmojiBloc({required this.repository}) : super(const EmojiState()) {
    on<LoadEmojiCategoriesEvent>(_onLoadCategories);
    on<LoadEmojisByCategoryEvent>(_onLoadEmojis);
    on<SetEmojiCategoryIdEvent>(_onSetCategoryId);
  }

  Future<void> _onLoadCategories(
    LoadEmojiCategoriesEvent event,
    Emitter<EmojiState> emit,
  ) async {
    emit(state.copyWith(categoriesState: RequestState.loading));

    final result = await repository.getCategories();

    switch (result) {
      case Success(data: final data):
        final categories = data.data ?? [];
        emit(state.copyWith(
          categories: categories,
          categoriesState: categories.isEmpty
              ? RequestState.empty
              : RequestState.loaded,
        ));
        if (categories.isNotEmpty && state.categoryId == null) {
          add(SetEmojiCategoryIdEvent(categoryId: categories.first.id));
          add(LoadEmojisByCategoryEvent(categoryId: categories.first.id));
        }
      case Failure(message: final message):
        emit(state.copyWith(
          categoriesState: RequestState.error,
          message: message,
        ));
    }
  }

  Future<void> _onLoadEmojis(
    LoadEmojisByCategoryEvent event,
    Emitter<EmojiState> emit,
  ) async {
    final catId = event.categoryId;

    if (state.categoryEmojis.containsKey(catId)) return;

    final newReqStates = Map<int, RequestState>.from(state.categoryReqStates);
    newReqStates[catId] = RequestState.loading;
    emit(state.copyWith(categoryReqStates: newReqStates));

    final result = await repository.getEmojis(catId);

    switch (result) {
      case Success(data: final data):
        final emojis = data.data ?? [];
        final newEmojis = Map<int, List<EmojiModel>>.from(state.categoryEmojis);
        newEmojis[catId] = emojis;
        final updatedReqStates =
            Map<int, RequestState>.from(state.categoryReqStates);
        updatedReqStates[catId] =
            emojis.isEmpty ? RequestState.empty : RequestState.loaded;
        emit(state.copyWith(
          categoryEmojis: newEmojis,
          categoryReqStates: updatedReqStates,
        ));
      case Failure(message: final message):
        final updatedReqStates =
            Map<int, RequestState>.from(state.categoryReqStates);
        updatedReqStates[catId] = RequestState.error;
        emit(state.copyWith(
          categoryReqStates: updatedReqStates,
          message: message,
        ));
    }
  }

  void _onSetCategoryId(
    SetEmojiCategoryIdEvent event,
    Emitter<EmojiState> emit,
  ) {
    emit(state.copyWith(categoryId: event.categoryId));
  }
}
