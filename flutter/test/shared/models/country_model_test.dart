import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/entities/country_entity.dart';
import 'package:utd_app/shared/models/country_model.dart';

/// Pure-Dart unit tests for [CountryModel].
///
/// Note the backend key mapping: `flag` -> photo, `e_name` -> nameEn,
/// `phone_code` -> phoneCode. All fields default to '' / 0 when missing.
void main() {
  group('CountryModel.fromJson', () {
    test('happy path: all fields populated, keys mapped correctly', () {
      final json = <String, dynamic>{
        'id': 20,
        'name': 'مصر',
        'flag': 'https://cdn/eg.png',
        'lang': 'ar',
        'phone_code': '+20',
        'iso': 'EG',
        'e_name': 'Egypt',
      };

      final c = CountryModel.fromJson(json);

      expect(c.id, 20);
      expect(c.name, 'مصر');
      // `flag` is mapped onto `photo`.
      expect(c.photo, 'https://cdn/eg.png');
      expect(c.lang, 'ar');
      // `phone_code` -> phoneCode.
      expect(c.phoneCode, '+20');
      expect(c.iso, 'EG');
      // `e_name` -> nameEn.
      expect(c.nameEn, 'Egypt');
    });

    test('empty json: all fields fall back to defaults (0 / empty string)', () {
      final c = CountryModel.fromJson(<String, dynamic>{});

      expect(c.id, 0);
      expect(c.name, '');
      expect(c.photo, '');
      expect(c.lang, '');
      expect(c.phoneCode, '');
      expect(c.iso, '');
      expect(c.nameEn, '');
    });

    test('explicit nulls coerce to defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'name': null,
        'flag': null,
        'lang': null,
        'phone_code': null,
        'iso': null,
        'e_name': null,
      };

      final c = CountryModel.fromJson(json);

      expect(c.id, 0);
      expect(c.name, '');
      expect(c.photo, '');
      expect(c.lang, '');
      expect(c.phoneCode, '');
      expect(c.iso, '');
      expect(c.nameEn, '');
    });

    test('using wrong key names (name vs e_name / flag) yields defaults', () {
      // The backend uses `flag` and `e_name`; supplying `photo`/`name_en`
      // (the Dart field names) is ignored — guards against silent key drift.
      final json = <String, dynamic>{
        'photo': 'ignored.png',
        'name_en': 'ignored',
      };

      final c = CountryModel.fromJson(json);

      expect(c.photo, '');
      expect(c.nameEn, '');
    });

    test('is an Equatable CountryEntity; value-equality holds', () {
      final a = CountryModel.fromJson({'id': 1, 'name': 'A'});
      final b = CountryModel.fromJson({'id': 1, 'name': 'A'});
      final diff = CountryModel.fromJson({'id': 2, 'name': 'A'});

      expect(a, isA<CountryEntity>());
      expect(a, equals(b));
      expect(a, isNot(equals(diff)));
    });
  });
}
