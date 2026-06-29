import 'dart:io';

import 'package:authentication/src/presentation/add_information/bloc/add_information_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/enums.dart';

void main() {
  // State holds TextEditingControllers / GlobalKey → need the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  AddInformationState fresh() => AddInformationState(
        formKey: GlobalKey<FormState>(),
        name: TextEditingController(),
        email: TextEditingController(),
        country: TextEditingController(),
      );

  group('AddInformationState defaults', () {
    test('selector + request defaults', () {
      final s = fresh();
      expect(s.gender, '');
      expect(s.birthday, '');
      expect(s.image, isNull);
      expect(s.requestState, RequestState.idle);
      expect(s.message, '');
      expect(s.name.text, '');
    });
  });

  group('AddInformationState.copyWith', () {
    test('gender/birthday are plain strings updated via copyWith', () {
      final s = fresh();
      final next = s.copyWith(gender: '1', birthday: '2000-01-01');
      expect(next.gender, '1');
      expect(next.birthday, '2000-01-01');
    });

    test('name/country/email write through the SHARED controller', () {
      final s = fresh();
      final next = s.copyWith(name: 'Ahmed', country: 'EG', email: 'a@b.com');
      // copyWith mutates the same controller and returns it.
      expect(next.name.text, 'Ahmed');
      expect(next.country.text, 'EG');
      expect(next.email.text, 'a@b.com');
      expect(identical(next.name, s.name), isTrue);
    });

    test('image is set and preserved when not passed', () {
      final s = fresh();
      final img = File('a.png');
      final withImg = s.copyWith(image: img);
      expect(withImg.image, img);
      // Subsequent copyWith without image keeps it.
      final kept = withImg.copyWith(message: 'x');
      expect(kept.image, img);
    });

    test('isImageNull clears the image even if one is held', () {
      final s = fresh().copyWith(image: File('a.png'));
      expect(s.image, isNotNull);
      final cleared = s.copyWith(isImageNull: true);
      expect(cleared.image, isNull);
    });

    test('isImageNull takes priority over a passed image', () {
      final s = fresh();
      final out = s.copyWith(image: File('b.png'), isImageNull: true);
      expect(out.image, isNull);
    });

    test('requestState + message round-trip', () {
      final s = fresh();
      final out = s.copyWith(requestState: RequestState.loading, message: 'm');
      expect(out.requestState, RequestState.loading);
      expect(out.message, 'm');
    });

    test('Equatable props read controller .text, so a text change is observed',
        () {
      final s = fresh();
      final before = s.props;
      s.copyWith(name: 'New');
      // props are computed live from name.text — re-reading reflects the change.
      expect(s.props, isNot(equals(before)));
      expect(s.props.contains('New'), isTrue);
    });
  });
}
