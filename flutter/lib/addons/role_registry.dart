import 'package:flutter/foundation.dart';

/// Definition of a role that a package contributes.
///
/// Roles use dot-namespaced keys to avoid collisions:
/// ```dart
/// RoleDefinition(key: 'agency.agent', label: 'Agent')
/// RoleDefinition(key: 'agency.host', label: 'Host')
/// ```
class RoleDefinition {
  final String key;
  final String label;
  final String? package;

  const RoleDefinition({
    required this.key,
    required this.label,
    this.package,
  });
}

/// Central registry for user roles across all packages.
///
/// Packages register their available [RoleDefinition]s during feature
/// initialization. The authenticated user's active roles are set from
/// the API response.
///
/// Usage from widgets:
/// ```dart
/// final roles = context.read<FeatureRegistry>().roleRegistry;
/// if (roles.hasRole('agency.agent')) { ... }
/// ```
class RoleRegistry extends ChangeNotifier {
  final Map<String, RoleDefinition> _definitions = {};
  final Set<String> _userRoles = {};

  void registerRoles(List<RoleDefinition> roles) {
    for (final role in roles) {
      _definitions[role.key] = role;
    }
  }

  void setUserRoles(List<String> roleKeys) {
    _userRoles
      ..clear()
      ..addAll(roleKeys);
    notifyListeners();
  }

  void clearUserRoles() {
    _userRoles.clear();
    notifyListeners();
  }

  bool hasRole(String key) => _userRoles.contains(key);

  Set<String> get userRoleKeys => Set.unmodifiable(_userRoles);

  List<RoleDefinition> get allDefinitions =>
      List.unmodifiable(_definitions.values);

  List<RoleDefinition> get userRoleDefinitions => _userRoles
      .where(_definitions.containsKey)
      .map((k) => _definitions[k]!)
      .toList();
}
