import 'package:flutter_test/flutter_test.dart';
import 'package:gifts/src/domain/entities/gift.dart';
import 'package:gifts/src/domain/entities/gift_category.dart';
import 'package:gifts/src/presentation/bloc/gift_picker_cubit.dart';

Gift _gift(int id) => Gift(
      id: id,
      name: 'g$id',
      type: 1,
      categoryId: 1,
      price: 10,
      img: '',
      showImg: '',
      imageType: 'png',
      vipLevel: 0,
    );

GiftCategory _cat(int id) => GiftCategory(id: id, title: 'c$id', type: 'normal');

void main() {
  group('GiftPickerState defaults', () {
    test('initial state has sensible defaults', () {
      const s = GiftPickerState();
      expect(s.status, GiftPickerStatus.initial);
      expect(s.categories, isEmpty);
      expect(s.gifts, isEmpty);
      expect(s.selectedCategoryId, isNull);
      expect(s.selectedGiftId, isNull);
      expect(s.quantity, 1);
      expect(s.sending, isFalse);
      expect(s.error, isNull);
      expect(s.recipients, isEmpty);
      expect(s.selectedRecipientIds, isEmpty);
    });
  });

  group('GiftPickerState.copyWith', () {
    test('overrides only the provided fields', () {
      const base = GiftPickerState();
      final next = base.copyWith(
        status: GiftPickerStatus.ready,
        gifts: [_gift(1), _gift(2)],
        categories: [_cat(1)],
        selectedCategoryId: 1,
        quantity: 5,
        sending: true,
      );
      expect(next.status, GiftPickerStatus.ready);
      expect(next.gifts.length, 2);
      expect(next.categories.length, 1);
      expect(next.selectedCategoryId, 1);
      expect(next.quantity, 5);
      expect(next.sending, isTrue);
      // untouched
      expect(next.selectedGiftId, isNull);
      expect(next.recipients, isEmpty);
    });

    test('omitted fields are preserved', () {
      final base = const GiftPickerState().copyWith(
        selectedGiftId: 42,
        selectedCategoryId: 3,
        quantity: 7,
      );
      final next = base.copyWith(status: GiftPickerStatus.loading);
      expect(next.selectedGiftId, 42);
      expect(next.selectedCategoryId, 3);
      expect(next.quantity, 7);
      expect(next.status, GiftPickerStatus.loading);
    });

    test('clearSelectedGift nulls the selected gift', () {
      final base = const GiftPickerState().copyWith(selectedGiftId: 9);
      expect(base.selectedGiftId, 9);
      final cleared = base.copyWith(clearSelectedGift: true);
      expect(cleared.selectedGiftId, isNull);
    });

    test('clearSelectedGift takes priority over a passed selectedGiftId', () {
      final base = const GiftPickerState().copyWith(selectedGiftId: 1);
      final next = base.copyWith(clearSelectedGift: true, selectedGiftId: 99);
      expect(next.selectedGiftId, isNull);
    });

    test('error is NOT preserved across copyWith (always reset to passed value)',
        () {
      // Note: copyWith assigns `error: error` (no `?? this.error`), so an
      // omitted error clears it. This is intentional (transient error).
      final withError = const GiftPickerState().copyWith(error: 'boom');
      expect(withError.error, 'boom');
      final next = withError.copyWith(status: GiftPickerStatus.ready);
      expect(next.error, isNull);
    });

    test('recipients and selectedRecipientIds round-trip', () {
      final next = const GiftPickerState().copyWith(
        selectedRecipientIds: {1, 2, 3},
      );
      expect(next.selectedRecipientIds, {1, 2, 3});
    });
  });

  group('GiftPickerState equality', () {
    test('identical field sets are equal', () {
      final a = const GiftPickerState().copyWith(
        status: GiftPickerStatus.ready,
        quantity: 2,
        selectedGiftId: 5,
      );
      final b = const GiftPickerState().copyWith(
        status: GiftPickerStatus.ready,
        quantity: 2,
        selectedGiftId: 5,
      );
      expect(a, equals(b));
    });

    test('differing quantity breaks equality', () {
      final a = const GiftPickerState().copyWith(quantity: 1);
      final b = const GiftPickerState().copyWith(quantity: 2);
      expect(a, isNot(equals(b)));
    });
  });
}
