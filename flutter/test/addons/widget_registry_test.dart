import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/addons/widget_registry.dart';

/// Pure-Dart tests for [WidgetRegistry]: register/lookup, duplicate-registration
/// guard, missing-key lookup, contains, names listing, and clear.
void main() {
  late WidgetRegistry registry;

  // A fresh instance per test → no shared state between tests.
  setUp(() => registry = WidgetRegistry());

  Widget builderA(BuildContext _) => const SizedBox(key: Key('a'));
  Widget builderB(BuildContext _) => const SizedBox(key: Key('b'));

  test('kSelfProfileWidget is the stable well-known key', () {
    expect(kSelfProfileWidget, 'profile.self');
  });

  test('register then contains/registeredWidgets reflect it', () {
    registry.register('w1', builderA);
    expect(registry.contains('w1'), isTrue);
    expect(registry.registeredWidgets, ['w1']);
  });

  test('build returns the built widget for a known name', () {
    registry.register('w1', builderA);
    final w = registry.build('w1', _FakeContext());
    expect(w, isA<SizedBox>());
    expect((w as SizedBox).key, const Key('a'));
  });

  test('build returns null for a missing name', () {
    expect(registry.build('nope', _FakeContext()), isNull);
  });

  test('contains is false for an unregistered name', () {
    expect(registry.contains('nope'), isFalse);
  });

  test('duplicate registration throws ArgumentError', () {
    registry.register('w1', builderA);
    expect(() => registry.register('w1', builderB), throwsArgumentError);
  });

  test('different names can coexist', () {
    registry.register('w1', builderA);
    registry.register('w2', builderB);
    expect(registry.registeredWidgets, containsAll(['w1', 'w2']));
    expect(registry.registeredWidgets.length, 2);
  });

  test('clear removes everything', () {
    registry.register('w1', builderA);
    registry.register('w2', builderB);
    registry.clear();
    expect(registry.registeredWidgets, isEmpty);
    expect(registry.contains('w1'), isFalse);
  });

  test('a name can be re-registered after clear', () {
    registry.register('w1', builderA);
    registry.clear();
    expect(() => registry.register('w1', builderB), returnsNormally);
  });
}

/// Minimal stand-in BuildContext: the test builders ignore it entirely.
class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
