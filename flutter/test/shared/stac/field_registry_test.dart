import 'package:flutter_test/flutter_test.dart';
// Imported through the stable re-export shim under utd_app (the path packages
// use), proving the shim resolves to the SDK's single FieldRegistry.
import 'package:utd_app/shared/stac/field_registry.dart';

/// Pure-Dart tests for the reference-counted [FieldRegistry] (static, shared).
///
/// State is fully static, so each test uses a UNIQUE id and balances every
/// [FieldRegistry.acquire] with [FieldRegistry.release] so nothing leaks across
/// tests and order never matters.
void main() {
  group('of', () {
    test('creates a controller lazily and returns the same one', () {
      const id = 'fr.of.same';
      expect(FieldRegistry.has(id), isFalse);
      final c1 = FieldRegistry.of(id);
      expect(FieldRegistry.has(id), isTrue);
      final c2 = FieldRegistry.of(id);
      expect(identical(c1, c2), isTrue);
      // of() does not take ownership, so the controller persists; dispose it
      // manually to avoid leaking into other tests.
      c1.dispose();
    });

    test('different ids get different controllers', () {
      final a = FieldRegistry.of('fr.of.a');
      final b = FieldRegistry.of('fr.of.b');
      expect(identical(a, b), isFalse);
      a.dispose();
      b.dispose();
    });
  });

  group('acquire / release lifecycle', () {
    test('acquire creates and has() reports it', () {
      const id = 'fr.acq.1';
      final c = FieldRegistry.acquire(id);
      expect(FieldRegistry.has(id), isTrue);
      // shared with of()
      expect(identical(FieldRegistry.of(id), c), isTrue);
      FieldRegistry.release(id);
      expect(FieldRegistry.has(id), isFalse);
    });

    test('single owner: release disposes the controller', () {
      const id = 'fr.acq.single';
      FieldRegistry.acquire(id);
      FieldRegistry.release(id);
      expect(FieldRegistry.has(id), isFalse);
    });

    test('two owners: controller survives until the last release', () {
      const id = 'fr.acq.two';
      final c1 = FieldRegistry.acquire(id);
      final c2 = FieldRegistry.acquire(id);
      expect(identical(c1, c2), isTrue); // same shared controller
      FieldRegistry.release(id); // one owner left
      expect(FieldRegistry.has(id), isTrue);
      FieldRegistry.release(id); // last owner leaves
      expect(FieldRegistry.has(id), isFalse);
    });

    test('the shared controller carries text across lookups', () {
      const id = 'fr.text';
      final owner = FieldRegistry.acquire(id);
      owner.text = 'hello';
      // a reader looking up by the same id sees the same text
      expect(FieldRegistry.of(id).text, 'hello');
      FieldRegistry.release(id);
    });
  });

  group('has', () {
    test('is false for an unknown id', () {
      expect(FieldRegistry.has('fr.unknown.${DateTime.now().microsecond}'),
          isFalse);
    });
  });
}
