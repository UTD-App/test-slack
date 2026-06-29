import 'package:audio_room/src/domain/blacklist_entry_model.dart';
import 'package:audio_room/src/domain/room_admin_model.dart';
import 'package:audio_room/src/domain/room_visitor_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlacklistEntryModel.fromJson', () {
    test('reads banned user id from `id` (backend convention)', () {
      final e = BlacklistEntryModel.fromJson({
        'id': 100,
        'user_id': 999, // should be ignored when `id` present
        'name': 'Bob',
        'avatar': 'bob.png',
        'country_flag': 'eg',
        'reason': 'spam',
        'banned_at': '2026-01-01T00:00:00Z',
        'expires_at': '2026-01-02T00:00:00Z',
        'remaining_seconds': 86400,
      });

      expect(e.userId, 100);
      expect(e.userName, 'Bob');
      expect(e.avatar, 'bob.png');
      expect(e.countryFlag, 'eg');
      expect(e.reason, 'spam');
      expect(e.bannedAt, DateTime.utc(2026, 1, 1));
      expect(e.expiresAt, DateTime.utc(2026, 1, 2));
      expect(e.remainingSeconds, 86400);
    });

    test('falls back to `user_id` when `id` is absent', () {
      final e = BlacklistEntryModel.fromJson({'user_id': 77, 'name': 'X'});
      expect(e.userId, 77);
    });

    test('defaults to 0 / empty when both ids missing', () {
      final e = BlacklistEntryModel.fromJson({'name': 'NoId'});
      expect(e.userId, 0);
      expect(e.userName, 'NoId');
    });

    test('null-safe optional fields', () {
      final e = BlacklistEntryModel.fromJson({'id': 1, 'name': 'A'});
      expect(e.avatar, isNull);
      expect(e.countryFlag, isNull);
      expect(e.reason, isNull);
      expect(e.bannedAt, isNull);
      expect(e.expiresAt, isNull);
      expect(e.remainingSeconds, isNull);
    });

    test('invalid date strings parse to null', () {
      final e = BlacklistEntryModel.fromJson({
        'id': 1,
        'name': 'A',
        'banned_at': 'nope',
        'expires_at': '',
      });
      expect(e.bannedAt, isNull);
      expect(e.expiresAt, isNull);
    });
  });

  group('RoomAdminModel.fromJson', () {
    test('parses a full admin', () {
      final a = RoomAdminModel.fromJson({
        'id': 5,
        'name': 'Admin',
        'avatar': 'a.png',
        'country_flag': 'sa',
        'assigned_at': '2026-03-03T12:00:00Z',
      });
      expect(a.id, 5);
      expect(a.name, 'Admin');
      expect(a.avatar, 'a.png');
      expect(a.countryFlag, 'sa');
      expect(a.assignedAt, DateTime.utc(2026, 3, 3, 12));
    });

    test('defaults and null-safety', () {
      final a = RoomAdminModel.fromJson(<String, dynamic>{});
      expect(a.id, 0);
      expect(a.name, '');
      expect(a.avatar, isNull);
      expect(a.assignedAt, isNull);
    });
  });

  group('RoomVisitorModel.fromJson', () {
    test('parses a full visitor', () {
      final v = RoomVisitorModel.fromJson({
        'id': 8,
        'name': 'Guest',
        'avatar': 'g.png',
        'country_flag': 'ae',
        'joined_at': '2026-04-04T08:00:00Z',
      });
      expect(v.id, 8);
      expect(v.name, 'Guest');
      expect(v.avatar, 'g.png');
      expect(v.countryFlag, 'ae');
      expect(v.joinedAt, DateTime.utc(2026, 4, 4, 8));
    });

    test('defaults and null-safety', () {
      final v = RoomVisitorModel.fromJson(<String, dynamic>{});
      expect(v.id, 0);
      expect(v.name, '');
      expect(v.avatar, isNull);
      expect(v.joinedAt, isNull);
    });
  });
}
