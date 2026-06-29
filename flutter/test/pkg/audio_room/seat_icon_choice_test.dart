import 'dart:io';

import 'package:audio_room/src/presentation/widgets/room/seats/seat_icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeatIconChoice constructors', () {
    test('defaultIcon', () {
      const c = SeatIconChoice.defaultIcon();
      expect(c.type, SeatIconChoiceType.defaultIcon);
      expect(c.presetName, isNull);
      expect(c.file, isNull);
    });

    test('preset carries name', () {
      const c = SeatIconChoice.preset('star');
      expect(c.type, SeatIconChoiceType.preset);
      expect(c.presetName, 'star');
      expect(c.file, isNull);
    });

    test('custom carries file', () {
      final f = File('icon.png');
      final c = SeatIconChoice.custom(f);
      expect(c.type, SeatIconChoiceType.custom);
      expect(c.file, f);
      expect(c.presetName, isNull);
    });

    test('pickFromGallery', () {
      const c = SeatIconChoice.pickFromGallery();
      expect(c.type, SeatIconChoiceType.pickFromGallery);
      expect(c.file, isNull);
      expect(c.presetName, isNull);
    });
  });

  group('presetIcons map', () {
    test('contains the documented preset keys mapped to IconData', () {
      expect(
        presetIcons.keys,
        containsAll(<String>[
          'star',
          'headphones',
          'music_note',
          'person',
          'favorite',
          'diamond',
        ]),
      );
      for (final v in presetIcons.values) {
        expect(v, isA<IconData>());
      }
    });
  });

  group('enums', () {
    test('SeatIconChoiceType has four variants', () {
      expect(SeatIconChoiceType.values, hasLength(4));
    });
    test('SeatIconType has empty + locked', () {
      expect(SeatIconType.values, [SeatIconType.empty, SeatIconType.locked]);
    });
  });
}
