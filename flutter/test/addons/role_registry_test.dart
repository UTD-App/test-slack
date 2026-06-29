import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/addons/role_registry.dart';

/// Pure-Dart tests for [RoleRegistry] and [RoleDefinition]:
/// register/override definitions, set/clear active user roles, hasRole, and the
/// derived userRoleDefinitions (only known roles).
void main() {
  late RoleRegistry registry;
  setUp(() => registry = RoleRegistry());

  group('RoleDefinition', () {
    test('holds its fields', () {
      const d = RoleDefinition(key: 'agency.agent', label: 'Agent', package: 'agency');
      expect(d.key, 'agency.agent');
      expect(d.label, 'Agent');
      expect(d.package, 'agency');
    });
  });

  group('registerRoles', () {
    test('registers definitions retrievable via allDefinitions', () {
      registry.registerRoles(const [
        RoleDefinition(key: 'agency.agent', label: 'Agent'),
        RoleDefinition(key: 'agency.host', label: 'Host'),
      ]);
      expect(registry.allDefinitions.map((d) => d.key),
          containsAll(['agency.agent', 'agency.host']));
      expect(registry.allDefinitions.length, 2);
    });

    test('re-registering the same key overwrites the previous definition', () {
      registry.registerRoles(const [RoleDefinition(key: 'k', label: 'Old')]);
      registry.registerRoles(const [RoleDefinition(key: 'k', label: 'New')]);
      expect(registry.allDefinitions.length, 1);
      expect(registry.allDefinitions.single.label, 'New');
    });
  });

  group('user roles', () {
    test('hasRole is false before any roles are set', () {
      expect(registry.hasRole('agency.agent'), isFalse);
      expect(registry.userRoleKeys, isEmpty);
    });

    test('setUserRoles replaces the active set', () {
      registry.setUserRoles(['a', 'b']);
      expect(registry.hasRole('a'), isTrue);
      expect(registry.hasRole('b'), isTrue);
      expect(registry.userRoleKeys, {'a', 'b'});

      registry.setUserRoles(['c']);
      expect(registry.hasRole('a'), isFalse);
      expect(registry.hasRole('c'), isTrue);
      expect(registry.userRoleKeys, {'c'});
    });

    test('clearUserRoles empties the active set', () {
      registry.setUserRoles(['a']);
      registry.clearUserRoles();
      expect(registry.hasRole('a'), isFalse);
      expect(registry.userRoleKeys, isEmpty);
    });
  });

  group('userRoleDefinitions', () {
    test('returns definitions only for known active roles', () {
      registry.registerRoles(const [
        RoleDefinition(key: 'agency.agent', label: 'Agent'),
        RoleDefinition(key: 'agency.host', label: 'Host'),
      ]);
      registry.setUserRoles(['agency.agent', 'unknown.role']);
      final defs = registry.userRoleDefinitions;
      expect(defs.length, 1);
      expect(defs.single.key, 'agency.agent');
    });

    test('is empty when active roles have no matching definitions', () {
      registry.setUserRoles(['x.y']);
      expect(registry.userRoleDefinitions, isEmpty);
    });
  });

  test('notifyListeners fires on set/clear roles', () {
    var count = 0;
    registry.addListener(() => count++);
    registry.setUserRoles(['a']);
    registry.clearUserRoles();
    expect(count, 2);
  });
}
