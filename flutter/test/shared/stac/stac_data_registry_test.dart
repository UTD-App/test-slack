import 'package:flutter_test/flutter_test.dart';
// Through the stable re-export shim under utd_app.
import 'package:utd_app/shared/stac/stac_data_registry.dart';

/// Pure-Dart tests for the [StacDataRegistry] singleton: list/object source
/// register + has + fetch, graceful empty defaults for missing/throwing
/// sources, overwrite-on-reregister, and the [revision] invalidate signal.
///
/// The registry is a process-wide singleton with no clear(); every test uses a
/// UNIQUE source key so registrations don't leak across tests.
void main() {
  final reg = StacDataRegistry.instance;

  group('list sources', () {
    test('register then has + fetch returns the data', () async {
      const key = 'sdr.list.basic';
      reg.registerList(key, () async => [
            {'id': 1},
            {'id': 2},
          ]);
      expect(reg.hasList(key), isTrue);
      final out = await reg.fetchList(key);
      expect(out.length, 2);
      expect(out.first['id'], 1);
    });

    test('fetch of a missing list source returns empty', () async {
      expect(reg.hasList('sdr.list.missing'), isFalse);
      expect(await reg.fetchList('sdr.list.missing'), isEmpty);
    });

    test('a throwing list source degrades to empty', () async {
      const key = 'sdr.list.throws';
      reg.registerList(key, () async => throw Exception('boom'));
      expect(await reg.fetchList(key), isEmpty);
    });

    test('re-registering a key overwrites the source', () async {
      const key = 'sdr.list.overwrite';
      reg.registerList(key, () async => [
            {'v': 1}
          ]);
      reg.registerList(key, () async => [
            {'v': 2}
          ]);
      final out = await reg.fetchList(key);
      expect(out.single['v'], 2);
    });
  });

  group('object sources', () {
    test('register then has + fetch returns the object', () async {
      const key = 'sdr.obj.basic';
      reg.registerObject(key, () async => {'name': 'Ann'});
      expect(reg.hasObject(key), isTrue);
      expect(await reg.fetchObject(key), {'name': 'Ann'});
    });

    test('fetch of a missing object source returns empty map', () async {
      expect(reg.hasObject('sdr.obj.missing'), isFalse);
      expect(await reg.fetchObject('sdr.obj.missing'), isEmpty);
    });

    test('a throwing object source degrades to empty map', () async {
      const key = 'sdr.obj.throws';
      reg.registerObject(key, () async => throw Exception('boom'));
      expect(await reg.fetchObject(key), isEmpty);
    });

    test('list and object namespaces are independent', () {
      const key = 'sdr.shared.key';
      reg.registerList(key, () async => const []);
      expect(reg.hasList(key), isTrue);
      expect(reg.hasObject(key), isFalse);
    });
  });

  group('revision / invalidate', () {
    test('invalidate bumps the revision notifier', () {
      final before = reg.revision.value;
      reg.invalidate();
      expect(reg.revision.value, before + 1);
    });

    test('invalidate notifies listeners', () {
      var fired = 0;
      void l() => fired++;
      reg.revision.addListener(l);
      reg.invalidate();
      reg.revision.removeListener(l);
      expect(fired, 1);
    });
  });
}
