import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/features/notifications/notification_models.dart';

/// Pure-Dart unit tests for [NotificationItem] + [NotificationActor].
void main() {
  group('NotificationItem.fromJson', () {
    test('happy path: all fields incl. nested actor + parsed date', () {
      final json = <String, dynamic>{
        'id': 100,
        'type': 'gift',
        'category': 'social',
        'title': 'New gift',
        'body': 'You received a rose',
        'icon': 'gift.png',
        'route': '/gifts/1',
        'data': {'gift_id': 1, 'amount': 5},
        'image_url': 'https://cdn/g.png',
        'is_read': true,
        'created_at': '2026-06-29T10:30:00Z',
        'actor': {'id': 9, 'name': 'Sara', 'avatar': 'sara.png'},
      };

      final n = NotificationItem.fromJson(json);

      expect(n.id, 100);
      expect(n.type, 'gift');
      expect(n.category, 'social');
      expect(n.title, 'New gift');
      expect(n.body, 'You received a rose');
      expect(n.icon, 'gift.png');
      expect(n.route, '/gifts/1');
      expect(n.data, {'gift_id': 1, 'amount': 5});
      expect(n.imageUrl, 'https://cdn/g.png');
      expect(n.isRead, true);
      expect(n.createdAt, DateTime.parse('2026-06-29T10:30:00Z'));
      expect(n.actor, isA<NotificationActor>());
      expect(n.actor!.id, 9);
      expect(n.actor!.name, 'Sara');
      expect(n.actor!.avatar, 'sara.png');
    });

    test('minimal json (only id): nullable fields null, others defaulted', () {
      final n = NotificationItem.fromJson(<String, dynamic>{'id': 1});

      expect(n.id, 1);
      expect(n.type, '');
      expect(n.category, isNull);
      expect(n.title, '');
      expect(n.body, '');
      expect(n.icon, isNull);
      expect(n.route, isNull);
      expect(n.data, isEmpty);
      expect(n.imageUrl, isNull);
      expect(n.actor, isNull);
      expect(n.isRead, false);
      expect(n.createdAt, isNull);
    });

    test('id accepts num (double) and coerces to int', () {
      final n = NotificationItem.fromJson({'id': 12.0});
      expect(n.id, 12);
    });

    // BUG: NotificationItem.fromJson does `(json['id'] as num).toInt()` with no
    // null guard, so a payload missing `id` (or with id:null) throws instead of
    // defaulting. All other fields are null-safe — id is the odd one out.
    test('BUG: missing/null id throws (no null-safety on id cast)', () {
      expect(() => NotificationItem.fromJson(<String, dynamic>{}),
          throwsA(isA<TypeError>()));
      expect(() => NotificationItem.fromJson(<String, dynamic>{'id': null}),
          throwsA(isA<TypeError>()));
    });

    test('invalid created_at string -> null (DateTime.tryParse)', () {
      final n = NotificationItem.fromJson({'id': 1, 'created_at': 'not-a-date'});
      expect(n.createdAt, isNull);
    });

    test('null data -> empty map default', () {
      final n = NotificationItem.fromJson({'id': 1, 'data': null});
      expect(n.data, isEmpty);
    });

    // BUG: `data` is parsed as `(json['data'] as Map?)?.cast(...)`. The `as Map?`
    // cast throws on a non-null, non-map value (e.g. a String) instead of
    // falling back to the empty-map default. Compare with `actor`, which uses an
    // `is Map` guard and is therefore safe. A malformed `data` field (server bug
    // or unexpected payload) crashes parsing of the whole notification.
    test('BUG: non-map (non-null) data throws instead of defaulting', () {
      expect(() => NotificationItem.fromJson({'id': 1, 'data': 'oops'}),
          throwsA(isA<TypeError>()));
    });

    test('dynamic-keyed data + actor maps cast safely', () {
      final json = <String, dynamic>{
        'id': 1,
        'data': <dynamic, dynamic>{'k': 'v'},
        'actor': <dynamic, dynamic>{'id': 3, 'name': 'X'},
      };

      final n = NotificationItem.fromJson(json);

      expect(n.data, {'k': 'v'});
      expect(n.actor!.id, 3);
      expect(n.actor!.name, 'X');
    });

    test('non-map actor -> null', () {
      final n = NotificationItem.fromJson({'id': 1, 'actor': 'nope'});
      expect(n.actor, isNull);
    });
  });

  group('NotificationItem.copyWith', () {
    test('only flips isRead; everything else preserved', () {
      final n = NotificationItem.fromJson({
        'id': 5,
        'type': 'gift',
        'title': 't',
        'body': 'b',
        'is_read': false,
        'actor': {'id': 1, 'name': 'A'},
        'created_at': '2026-06-29T10:00:00Z',
      });

      final read = n.copyWith(isRead: true);

      expect(read.isRead, true);
      expect(read.id, n.id);
      expect(read.type, n.type);
      expect(read.title, n.title);
      expect(read.body, n.body);
      expect(read.actor, n.actor);
      expect(read.createdAt, n.createdAt);
    });

    test('copyWith with no args keeps isRead unchanged', () {
      final n = NotificationItem.fromJson({'id': 1, 'is_read': true});
      expect(n.copyWith().isRead, true);
    });
  });

  group('NotificationActor.fromJson', () {
    test('happy path', () {
      final a = NotificationActor.fromJson({
        'id': 9,
        'name': 'Sara',
        'avatar': 'sara.png',
      });
      expect(a.id, 9);
      expect(a.name, 'Sara');
      expect(a.avatar, 'sara.png');
    });

    test('empty json: id defaults 0, name/avatar null', () {
      final a = NotificationActor.fromJson(<String, dynamic>{});
      expect(a.id, 0);
      expect(a.name, isNull);
      expect(a.avatar, isNull);
    });

    test('id accepts num/double', () {
      expect(NotificationActor.fromJson({'id': 4.0}).id, 4);
    });
  });
}
