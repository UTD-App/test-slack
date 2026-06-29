import 'package:audio_room/audio_room.dart';
import 'package:audio_room_mode_cinema/audio_room_mode_cinema.dart';
import 'package:audio_room_mode_couples/audio_room_mode_couples.dart';
import 'package:audio_room_mode_seats12/audio_room_mode_seats12.dart';
import 'package:audio_room_mode_seats16/audio_room_mode_seats16.dart';
import 'package:audio_room_mode_seats2/audio_room_mode_seats2.dart';
import 'package:audio_room_mode_seats22/audio_room_mode_seats22.dart';
import 'package:audio_room_mode_seats8/audio_room_mode_seats8.dart';
import 'package:flutter_test/flutter_test.dart';

/// All mode plugins that ship with the app, keyed by an expected metadata tuple.
List<AudioRoomModePlugin> _allModes() => [
      Seats2ModePlugin(),
      Seats8ModePlugin(),
      Seats12ModePlugin(),
      Seats16ModePlugin(),
      Seats22ModePlugin(),
      CinemaModePlugin(),
      CouplesModePlugin(),
    ];

void main() {
  group('mode plugin metadata', () {
    test('seats8 metadata', () {
      final p = Seats8ModePlugin();
      expect(p.id, 'seats8');
      expect(p.backendCode, '8');
      expect(p.rtmKey, 'eight');
      expect(p.seatCount, 8);
      expect(p.isPaid, false);
      expect(p.gridRows, isNull);
    });

    test('seats2 (Date) is paid', () {
      final p = Seats2ModePlugin();
      expect(p.backendCode, '6');
      expect(p.seatCount, 2);
      expect(p.isPaid, true);
    });

    test('seats12 grid covers all seats once', () {
      final p = Seats12ModePlugin();
      expect(p.backendCode, '2');
      expect(p.seatCount, 12);
      final flat = p.gridRows!.expand((r) => r).toList()..sort();
      expect(flat, List.generate(12, (i) => i));
    });

    test('seats16 (Party) grid covers all seats once', () {
      final p = Seats16ModePlugin();
      expect(p.backendCode, '1');
      expect(p.rtmKey, 'party');
      expect(p.seatCount, 16);
      final flat = p.gridRows!.expand((r) => r).toList()..sort();
      expect(flat, List.generate(16, (i) => i));
    });

    test('seats22 uses previewRows (custom layout) covering all seats', () {
      final p = Seats22ModePlugin();
      expect(p.gridRows, isNull);
      expect(p.seatCount, 22);
      final flat = p.previewRows.expand((r) => r).toList()..sort();
      expect(flat, List.generate(22, (i) => i));
    });

    test('cinema and couples metadata', () {
      final cinema = CinemaModePlugin();
      expect(cinema.backendCode, '5');
      expect(cinema.seatCount, 8);
      expect(cinema.isPaid, true);

      final couples = CouplesModePlugin();
      expect(couples.backendCode, '9');
      expect(couples.seatCount, 8);
      // NOTE: couples reuses the 'seats8' rtmKey (distinct from seats8's 'eight').
      expect(couples.rtmKey, 'seats8');
    });
  });

  group('cross-plugin invariants', () {
    test('backend codes are unique across all installed modes', () {
      final codes = _allModes().map((p) => p.backendCode).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('every mode reports a positive seat count and divisor', () {
      for (final p in _allModes()) {
        expect(p.seatCount, greaterThan(0), reason: p.id);
        expect(p.seatSizeDivisor, greaterThan(0), reason: p.id);
      }
    });

    test('grid-based modes: gridRows seats == seatCount', () {
      for (final p in _allModes().where((p) => p.gridRows != null)) {
        final flat = p.gridRows!.expand((r) => r).toList();
        expect(flat.length, p.seatCount, reason: p.id);
        expect(flat.toSet().length, p.seatCount, reason: 'dup seats in ${p.id}');
      }
    });
  });

  group('previewRows default behaviour (base AudioRoomModePlugin)', () {
    test('falls back to gridRows when not overridden (grid mode)', () {
      final p = Seats12ModePlugin();
      expect(p.previewRows, p.gridRows);
    });

    test('falls back to a single row of all seats when gridRows null & not overridden', () {
      // seats8 has gridRows null and does NOT override previewRows.
      final p = Seats8ModePlugin();
      expect(p.previewRows, [List.generate(8, (i) => i)]);
    });
  });

  group('toUTDRoomMode mapping', () {
    test('maps backendCode, seatCount, displayName, rows', () {
      final p = Seats16ModePlugin();
      final mode = p.toUTDRoomMode();
      expect(mode.id, p.backendCode);
      expect(mode.seatCount, p.seatCount);
      expect(mode.displayName, p.displayName);
      expect(mode.rows, p.previewRows);
    });

    test('grid mode has null containerBuilder; custom-layout mode supplies one', () {
      // grid (seats12) -> gridRows != null -> no custom container builder
      expect(Seats12ModePlugin().toUTDRoomMode().containerBuilder, isNull);
      // custom layout (seats8) -> gridRows == null -> builder provided
      expect(Seats8ModePlugin().toUTDRoomMode().containerBuilder, isNotNull);
    });
  });
}
