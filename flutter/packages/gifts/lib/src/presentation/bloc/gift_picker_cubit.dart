import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gift.dart';
import '../../domain/entities/gift_category.dart';
import '../../domain/repositories/gift_repository.dart';

enum GiftPickerStatus { initial, loading, ready, error }

class GiftPickerState extends Equatable {
  final GiftPickerStatus status;
  final List<GiftCategory> categories;
  final List<Gift> gifts;
  final int? selectedCategoryId;
  final int? selectedGiftId;
  final int quantity;
  final bool sending;
  final String? error;

  const GiftPickerState({
    this.status = GiftPickerStatus.initial,
    this.categories = const [],
    this.gifts = const [],
    this.selectedCategoryId,
    this.selectedGiftId,
    this.quantity = 1,
    this.sending = false,
    this.error,
  });

  GiftPickerState copyWith({
    GiftPickerStatus? status,
    List<GiftCategory>? categories,
    List<Gift>? gifts,
    int? selectedCategoryId,
    int? selectedGiftId,
    bool clearSelectedGift = false,
    int? quantity,
    bool? sending,
    String? error,
  }) {
    return GiftPickerState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      gifts: gifts ?? this.gifts,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedGiftId: clearSelectedGift ? null : (selectedGiftId ?? this.selectedGiftId),
      quantity: quantity ?? this.quantity,
      sending: sending ?? this.sending,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, categories, gifts, selectedCategoryId, selectedGiftId, quantity, sending, error];
}

class GiftPickerCubit extends Cubit<GiftPickerState> {
  final GiftRepository repository;

  GiftPickerCubit(this.repository) : super(const GiftPickerState());

  Future<void> load() async {
    emit(state.copyWith(status: GiftPickerStatus.loading, error: null));
    final res = await repository.fetchCategories();
    await res.when(
      success: (categories) async {
        final firstId = categories.isNotEmpty ? categories.first.id : null;
        emit(state.copyWith(categories: categories, selectedCategoryId: firstId));
        await _loadGifts(firstId);
      },
      failure: (msg, _) async => emit(state.copyWith(status: GiftPickerStatus.error, error: msg)),
    );
  }

  Future<void> selectCategory(int categoryId) async {
    if (categoryId == state.selectedCategoryId) return;
    emit(state.copyWith(selectedCategoryId: categoryId, clearSelectedGift: true, gifts: const []));
    await _loadGifts(categoryId);
  }

  Future<void> _loadGifts(int? categoryId) async {
    emit(state.copyWith(status: GiftPickerStatus.loading, error: null));
    final res = await repository.fetchGifts(categoryId: categoryId);
    res.when(
      success: (gifts) => emit(state.copyWith(status: GiftPickerStatus.ready, gifts: gifts)),
      failure: (msg, _) => emit(state.copyWith(status: GiftPickerStatus.error, error: msg)),
    );
  }

  void selectGift(int giftId) => emit(state.copyWith(selectedGiftId: giftId));

  void setQuantity(int quantity) => emit(state.copyWith(quantity: quantity.clamp(1, 9999)));

  /// Returns true on success.
  Future<bool> send({required String contextType, required int contextId}) async {
    final giftId = state.selectedGiftId;
    if (giftId == null || state.sending) return false;

    emit(state.copyWith(sending: true, error: null));
    final res = await repository.sendInContext(
      contextType: contextType,
      contextId: contextId,
      giftId: giftId,
      quantity: state.quantity,
    );
    emit(state.copyWith(sending: false));

    return res.isSuccess && (res.dataOrNull ?? false);
  }
}
