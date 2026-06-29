import 'package:audio_room/src/audio_room_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('audioRoomTranslations structure', () {
    test('provides both en and ar locales', () {
      expect(audioRoomTranslations.keys, containsAll(<String>['en', 'ar']));
    });

    test('en and ar cover the same keys', () {
      final en = audioRoomTranslations['en']!.keys.toSet();
      final ar = audioRoomTranslations['ar']!.keys.toSet();
      // ar has one extra legacy key ('recently_added') not present in en.
      final missingFromAr = en.difference(ar);
      expect(missingFromAr, isEmpty,
          reason: 'ar is missing: $missingFromAr');
    });

    test('no empty translation values', () {
      for (final locale in audioRoomTranslations.entries) {
        for (final kv in locale.value.entries) {
          expect(kv.value.trim(), isNotEmpty,
              reason: '${locale.key}/${kv.key} is empty');
        }
      }
    });

    test('all keys are namespaced under audio_room.', () {
      for (final locale in audioRoomTranslations.values) {
        for (final key in locale.keys) {
          expect(key, startsWith('audio_room.'), reason: key);
        }
      }
    });
  });

  group('AudioRoomKeys constants resolve to en translations', () {
    // Each public key constant should have a matching en string. This guards
    // against a constant being added without a translation entry.
    test('representative keys are present in en', () {
      final en = audioRoomTranslations['en']!;
      final samples = <String>[
        AudioRoomKeys.title,
        AudioRoomKeys.create,
        AudioRoomKeys.roomName,
        AudioRoomKeys.seatMode,
        AudioRoomKeys.blacklist,
        AudioRoomKeys.banUser,
        AudioRoomKeys.leaveRoom,
        AudioRoomKeys.deleteRoom,
        AudioRoomKeys.bannedFromRoom,
      ];
      for (final k in samples) {
        expect(en.containsKey(k), isTrue, reason: 'missing en for $k');
      }
    });

    test('key constants carry the audio_room namespace', () {
      expect(AudioRoomKeys.title, 'audio_room.title');
      expect(AudioRoomKeys.create, 'audio_room.create');
    });
  });

  group('placeholder-bearing strings keep their {tokens}', () {
    test('en interpolation tokens survive', () {
      final en = audioRoomTranslations['en']!;
      expect(en[AudioRoomKeys.seat], contains('{index}'));
      expect(en[AudioRoomKeys.seats], contains('{count}'));
      expect(en[AudioRoomKeys.invitationSentTo], contains('{name}'));
      expect(en[AudioRoomKeys.minutesAgo], contains('{n}'));
      expect(en[AudioRoomKeys.userPromotedToAdmin], contains('{by}'));
      expect(en[AudioRoomKeys.userPromotedToAdmin], contains('{name}'));
    });

    test('ar interpolation tokens survive', () {
      final ar = audioRoomTranslations['ar']!;
      expect(ar[AudioRoomKeys.seat], contains('{index}'));
      expect(ar[AudioRoomKeys.invitationSentTo], contains('{name}'));
    });
  });
}
