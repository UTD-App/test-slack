import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/features/notifications/notification_data_extension.dart';

/// Pure-Dart tests for NotificationDataExtension — the unread-count badge model.
/// Covers onDataReceived parsing, serialize, clear, and the
/// setUnread/increment/decrement mutators incl. their clamping/guards.
void main() {
  group('NotificationDataExtension', () {
    late NotificationDataExtension ext;
    late int notifyCount;

    setUp(() {
      ext = NotificationDataExtension();
      notifyCount = 0;
      ext.addListener(() => notifyCount++);
    });

    tearDown(() => ext.dispose());

    test('key is "notifications"', () {
      expect(ext.key, 'notifications');
    });

    test('default unreadCount is 0', () {
      expect(ext.unreadCount, 0);
    });

    group('onDataReceived', () {
      test('reads unread_count and notifies', () {
        ext.onDataReceived({'unread_count': 5});
        expect(ext.unreadCount, 5);
        expect(notifyCount, 1);
      });

      test('null data -> 0', () {
        ext.onDataReceived({'unread_count': 9});
        ext.onDataReceived(null);
        expect(ext.unreadCount, 0);
      });

      test('missing key -> 0', () {
        ext.onDataReceived({'other': 1});
        expect(ext.unreadCount, 0);
      });

      test('num (double) is truncated to int', () {
        ext.onDataReceived({'unread_count': 3.9});
        expect(ext.unreadCount, 3);
      });
    });

    group('serializeData', () {
      test('returns current count', () {
        ext.setUnread(8);
        expect(ext.serializeData(), {'unread_count': 8});
      });
    });

    group('onDataCleared', () {
      test('resets to 0 and notifies', () {
        ext.setUnread(6);
        notifyCount = 0;
        ext.onDataCleared();
        expect(ext.unreadCount, 0);
        expect(notifyCount, 1);
      });
    });

    group('setUnread', () {
      test('sets exact value', () {
        ext.setUnread(11);
        expect(ext.unreadCount, 11);
        expect(notifyCount, 1);
      });
      test('negative clamps to 0', () {
        ext.setUnread(-3);
        expect(ext.unreadCount, 0);
      });
      test('zero is allowed', () {
        ext.setUnread(0);
        expect(ext.unreadCount, 0);
      });
    });

    group('increment', () {
      test('bumps by one and notifies', () {
        ext.increment();
        ext.increment();
        expect(ext.unreadCount, 2);
        expect(notifyCount, 2);
      });
    });

    group('decrement', () {
      test('decreases by one when > 0', () {
        ext.setUnread(2);
        notifyCount = 0;
        ext.decrement();
        expect(ext.unreadCount, 1);
        expect(notifyCount, 1);
      });
      test('does NOT go below 0 and does not notify at floor', () {
        expect(ext.unreadCount, 0);
        notifyCount = 0;
        ext.decrement();
        expect(ext.unreadCount, 0);
        expect(notifyCount, 0, reason: 'guard skips notify when already 0');
      });
    });
  });
}
