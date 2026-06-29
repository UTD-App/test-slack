import 'package:flutter_test/flutter_test.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StacDataRegistry — list sources', () {
    final reg = StacDataRegistry.instance;

    test('hasList reflects registration', () {
      expect(reg.hasList('t.missing'), isFalse);
      reg.registerList('t.list', () async => [
            {'id': 1},
          ]);
      expect(reg.hasList('t.list'), isTrue);
    });

    test('fetchList returns the source data', () async {
      reg.registerList('t.list2', () async => [
            {'id': 1},
            {'id': 2},
          ]);
      final out = await reg.fetchList('t.list2');
      expect(out, hasLength(2));
      expect(out.first['id'], 1);
    });

    test('fetchList on a missing key returns an empty list', () async {
      expect(await reg.fetchList('nope.list'), isEmpty);
    });

    test('fetchList swallows a throwing source and returns empty', () async {
      reg.registerList('t.throws', () async => throw Exception('boom'));
      expect(await reg.fetchList('t.throws'), isEmpty);
    });

    test('re-registering a key overrides the previous source', () async {
      reg.registerList('t.dup', () async => [
            {'v': 'old'},
          ]);
      reg.registerList('t.dup', () async => [
            {'v': 'new'},
          ]);
      final out = await reg.fetchList('t.dup');
      expect(out.single['v'], 'new');
    });
  });

  group('StacDataRegistry — object sources', () {
    final reg = StacDataRegistry.instance;

    test('hasObject + fetchObject round-trip', () async {
      expect(reg.hasObject('t.missingObj'), isFalse);
      reg.registerObject('t.user', () async => {'name': 'Ahmed'});
      expect(reg.hasObject('t.user'), isTrue);
      expect((await reg.fetchObject('t.user'))['name'], 'Ahmed');
    });

    test('fetchObject on a missing key returns empty map', () async {
      expect(await reg.fetchObject('nope.obj'), isEmpty);
    });

    test('fetchObject swallows a throwing source', () async {
      reg.registerObject('t.objThrows', () async => throw Exception('x'));
      expect(await reg.fetchObject('t.objThrows'), isEmpty);
    });
  });

  group('StacDataRegistry — revision', () {
    test('invalidate bumps the revision notifier', () {
      final reg = StacDataRegistry.instance;
      final before = reg.revision.value;
      var notified = 0;
      void listener() => notified++;
      reg.revision.addListener(listener);
      addTearDown(() => reg.revision.removeListener(listener));

      reg.invalidate();
      reg.invalidate();

      expect(reg.revision.value, before + 2);
      expect(notified, 2);
    });
  });

  group('FieldRegistry — shared controllers + refcounting', () {
    test('of() lazily creates and shares a controller by id', () {
      const id = 'fr.email';
      expect(FieldRegistry.has(id), isFalse);
      final a = FieldRegistry.of(id);
      final b = FieldRegistry.of(id);
      expect(identical(a, b), isTrue);
      expect(FieldRegistry.has(id), isTrue);
      // of() does not take ownership → still disposed by acquire/release pairs.
      // Clean up manually for this readers-only id.
      a.dispose();
      // Remove from map by acquiring then releasing? It was never owned; leave it.
    });

    test('controller is disposed only when the LAST owner releases', () {
      const id = 'fr.shared';
      final c1 = FieldRegistry.acquire(id); // owner 1
      final c2 = FieldRegistry.acquire(id); // owner 2 (same controller)
      expect(identical(c1, c2), isTrue);

      FieldRegistry.release(id); // one owner left
      expect(FieldRegistry.has(id), isTrue, reason: 'peer still holds it');

      FieldRegistry.release(id); // last owner leaves
      expect(FieldRegistry.has(id), isFalse, reason: 'disposed + removed');
    });

    test('acquire then single release disposes and removes it', () {
      const id = 'fr.single';
      FieldRegistry.acquire(id);
      expect(FieldRegistry.has(id), isTrue);
      FieldRegistry.release(id);
      expect(FieldRegistry.has(id), isFalse);
    });

    test('text written via the shared controller is visible to a peer reader',
        () {
      const id = 'fr.text';
      final owner = FieldRegistry.acquire(id);
      owner.text = 'hi';
      final reader = FieldRegistry.of(id);
      expect(reader.text, 'hi');
      FieldRegistry.release(id);
    });
  });
}
