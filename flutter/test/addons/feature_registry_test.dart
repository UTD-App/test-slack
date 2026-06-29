import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/addons/app_feature.dart';
import 'package:utd_app/addons/feature_registry.dart';
import 'package:utd_app/addons/role_registry.dart';
import 'package:utd_app/addons/settings_registry.dart';
import 'package:utd_app/addons/ui_contribution.dart';
import 'package:utd_app/addons/ui_slot.dart';
import 'package:utd_app/addons/user_data_extension.dart';
import 'package:utd_app/addons/widget_registry.dart';

Widget _noop(BuildContext _) => const SizedBox();

/// A configurable test feature so each test builds exactly the surface it needs.
class _TestFeature extends AppFeature {
  _TestFeature(
    this._id, {
    String? displayName,
    List<UiContribution>? contributions,
    List<GoRoute>? routes,
    List<RoleDefinition>? roles,
    List<UserSettingDefinition>? settings,
    List<UserDataExtension>? extensions,
    Map<String, Map<String, String>>? translations,
    List<String> deps = const [],
    String? compatError,
    this.onInit,
    Map<String, WidgetBuilder>? widgets,
  })  : _displayName = displayName ?? _id,
        _contributions = contributions ?? const [],
        _routes = routes ?? const [],
        _roles = roles ?? const [],
        _settings = settings ?? const [],
        _extensions = extensions ?? const [],
        _translations = translations ?? const {},
        _deps = deps,
        _compatError = compatError,
        _widgets = widgets ?? const {};

  final String _id;
  final String _displayName;
  final List<UiContribution> _contributions;
  final List<GoRoute> _routes;
  final List<RoleDefinition> _roles;
  final List<UserSettingDefinition> _settings;
  final List<UserDataExtension> _extensions;
  final Map<String, Map<String, String>> _translations;
  final List<String> _deps;
  final String? _compatError;
  final Map<String, WidgetBuilder> _widgets;
  final void Function()? onInit;

  @override
  String get id => _id;
  @override
  String get displayName => _displayName;
  @override
  List<String> get dependencies => _deps;
  @override
  List<UiContribution> getUiContributions() => _contributions;
  @override
  List<GoRoute> getRoutes() => _routes;
  @override
  List<RoleDefinition> getRoleDefinitions() => _roles;
  @override
  List<UserSettingDefinition> getSettingDefinitions() => _settings;
  @override
  List<UserDataExtension> getUserDataExtensions() => _extensions;
  @override
  Map<String, Map<String, String>> getTranslations() => _translations;
  @override
  String? validateCompatibility() => _compatError;
  @override
  Future<void> initialize() async => onInit?.call();
  @override
  void registerWidgets(WidgetRegistry registry) {
    _widgets.forEach(registry.register);
  }
}

class _FakeUserDataExt extends UserDataExtension {
  _FakeUserDataExt(this.key);
  @override
  final String key;
  Map<String, dynamic>? received;
  bool cleared = false;
  Map<String, dynamic>? toSerialize;

  @override
  void onDataReceived(Map<String, dynamic>? data) => received = data;
  @override
  void onDataCleared() => cleared = true;
  @override
  Map<String, dynamic>? serializeData() => toSerialize;
}

void main() {
  late FeatureRegistry registry;
  setUp(() => registry = FeatureRegistry());

  group('addFeature', () {
    test('adds a feature to allFeatures and features', () {
      final f = _TestFeature('a');
      registry.addFeature(f);
      expect(registry.allFeatures, [f]);
      expect(registry.features, [f]);
    });

    test('duplicate id throws ArgumentError', () {
      registry.addFeature(_TestFeature('a'));
      expect(() => registry.addFeature(_TestFeature('a')), throwsArgumentError);
    });

    test('addFeatures adds many in order', () {
      registry.addFeatures([_TestFeature('a'), _TestFeature('b')]);
      expect(registry.allFeatures.map((f) => f.id), ['a', 'b']);
    });

    test('addFeatures throws on a duplicate within the batch', () {
      expect(
        () => registry.addFeatures([_TestFeature('a'), _TestFeature('a')]),
        throwsArgumentError,
      );
    });
  });

  group('enable / disable gating', () {
    test('isFeatureEnabled is true by default', () {
      registry.addFeature(_TestFeature('a'));
      expect(registry.isFeatureEnabled('a'), isTrue);
    });

    test('setDisabledFeatures hides from features but keeps allFeatures', () {
      registry.addFeatures([_TestFeature('a'), _TestFeature('b')]);
      registry.setDisabledFeatures({'a'});
      expect(registry.isFeatureEnabled('a'), isFalse);
      expect(registry.features.map((f) => f.id), ['b']);
      expect(registry.allFeatures.map((f) => f.id), ['a', 'b']);
      expect(registry.disabledFeatureIds, {'a'});
    });

    test('setDisabledFeatures replaces the prior disabled set', () {
      registry.addFeatures([_TestFeature('a'), _TestFeature('b')]);
      registry.setDisabledFeatures({'a'});
      registry.setDisabledFeatures({'b'});
      expect(registry.isFeatureEnabled('a'), isTrue);
      expect(registry.isFeatureEnabled('b'), isFalse);
    });

    test('disabled features contribute no routes/contributions', () {
      registry.addFeature(_TestFeature(
        'a',
        routes: [GoRoute(path: '/a', builder: (_, __) => const SizedBox())],
        contributions: [UiContribution(slot: UiSlot.home, builder: _noop)],
      ));
      registry.setDisabledFeatures({'a'});
      expect(registry.aggregateRoutes(), isEmpty);
      expect(registry.getUiContributions(UiSlot.home), isEmpty);
    });
  });

  group('aggregateRoutes', () {
    test('combines routes in registration order', () {
      registry.addFeature(_TestFeature('a',
          routes: [GoRoute(path: '/a', builder: (_, __) => const SizedBox())]));
      registry.addFeature(_TestFeature('b', routes: [
        GoRoute(path: '/b1', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/b2', builder: (_, __) => const SizedBox()),
      ]));
      expect(registry.aggregateRoutes().map((r) => r.path), ['/a', '/b1', '/b2']);
    });

    test('is empty with no features', () {
      expect(registry.aggregateRoutes(), isEmpty);
    });
  });

  group('getUiContributionDescriptors', () {
    test('single contribution per slot always renders', () {
      registry.addFeature(_TestFeature('a',
          contributions: [UiContribution(slot: UiSlot.home, builder: _noop)]));
      final descs = registry.getUiContributionDescriptors(UiSlot.home);
      expect(descs.length, 1);
      expect(descs.single.featureId, 'a');
      expect(descs.single.key, 'home::a::0');
    });

    test('orders across features by contribution.order', () {
      registry.addFeature(_TestFeature('a', contributions: [
        UiContribution(slot: UiSlot.home, builder: _noop, order: 10),
      ]));
      registry.addFeature(_TestFeature('b', contributions: [
        UiContribution(slot: UiSlot.home, builder: _noop, order: 1),
      ]));
      final descs = registry.getUiContributionDescriptors(UiSlot.home);
      expect(descs.map((d) => d.featureId), ['b', 'a']);
    });

    test('keeps a feature contributions to multiple DIFFERENT slots', () {
      registry.addFeature(_TestFeature('a', contributions: [
        UiContribution(slot: UiSlot.drawer, builder: _noop),
        UiContribution(slot: UiSlot.userProfile, builder: _noop),
      ]));
      expect(registry.getUiContributionDescriptors(UiSlot.drawer).length, 1);
      expect(registry.getUiContributionDescriptors(UiSlot.userProfile).length, 1);
    });

    test('multiple alternatives for the SAME slot default to the first', () {
      registry.addFeature(_TestFeature('a', contributions: [
        UiContribution(slot: UiSlot.home, builder: _noop, label: 'first'),
        UiContribution(slot: UiSlot.home, builder: _noop, label: 'second'),
      ]));
      final descs = registry.getUiContributionDescriptors(UiSlot.home);
      expect(descs.length, 1);
      expect(descs.single.contribution.label, 'first');
      expect(descs.single.key, 'home::a::0');
    });

    test('selection picks an alternative for the same slot', () {
      registry.addFeature(_TestFeature('a', contributions: [
        UiContribution(slot: UiSlot.home, builder: _noop, label: 'first'),
        UiContribution(slot: UiSlot.home, builder: _noop, label: 'second'),
      ]));
      // key form: '<slot.name>::<featureId>::<index>'
      registry.setSelectedContributions({'a': 'home::a::1'});
      final descs = registry.getUiContributionDescriptors(UiSlot.home);
      expect(descs.single.contribution.label, 'second');
      expect(descs.single.key, 'home::a::1');
    });

    test('a selection targeting another slot is ignored (defaults to first)', () {
      registry.addFeature(_TestFeature('a', contributions: [
        UiContribution(slot: UiSlot.home, builder: _noop, label: 'first'),
        UiContribution(slot: UiSlot.home, builder: _noop, label: 'second'),
      ]));
      registry.setSelectedContributions({'a': 'drawer::a::0'});
      final descs = registry.getUiContributionDescriptors(UiSlot.home);
      expect(descs.single.contribution.label, 'first');
    });

    test('empty for a slot with no contributions', () {
      registry.addFeature(_TestFeature('a',
          contributions: [UiContribution(slot: UiSlot.home, builder: _noop)]));
      expect(registry.getUiContributionDescriptors(UiSlot.settings), isEmpty);
    });
  });

  group('contribution ordering overrides', () {
    test('setContributionOrder overrides the natural order', () {
      registry.addFeature(_TestFeature('a',
          contributions: [UiContribution(slot: UiSlot.home, builder: _noop, order: 0)]));
      registry.addFeature(_TestFeature('b',
          contributions: [UiContribution(slot: UiSlot.home, builder: _noop, order: 0)]));
      // Without override, registration order is a, b. Override flips them.
      registry.setContributionOrder(UiSlot.home, ['home::b::0', 'home::a::0']);
      final descs = registry.getUiContributionDescriptors(UiSlot.home);
      expect(descs.map((d) => d.featureId), ['b', 'a']);
    });

    test('resetContributionOrder restores natural order for that slot', () {
      registry.addFeature(_TestFeature('a',
          contributions: [UiContribution(slot: UiSlot.home, builder: _noop)]));
      registry.addFeature(_TestFeature('b',
          contributions: [UiContribution(slot: UiSlot.home, builder: _noop)]));
      registry.setContributionOrder(UiSlot.home, ['home::b::0', 'home::a::0']);
      registry.resetContributionOrder(UiSlot.home);
      final descs = registry.getUiContributionDescriptors(UiSlot.home);
      expect(descs.map((d) => d.featureId), ['a', 'b']);
    });
  });

  group('getAllUiContributions', () {
    test('only includes slots that have contributions', () {
      registry.addFeature(_TestFeature('a', contributions: [
        UiContribution(slot: UiSlot.home, builder: _noop),
        UiContribution(slot: UiSlot.drawer, builder: _noop),
      ]));
      final all = registry.getAllUiContributions();
      expect(all.keys, containsAll([UiSlot.home, UiSlot.drawer]));
      expect(all.containsKey(UiSlot.settings), isFalse);
    });
  });

  group('getFeatureContributionDescriptors', () {
    test('returns all contributions of one feature across slots', () {
      registry.addFeature(_TestFeature('a', contributions: [
        UiContribution(slot: UiSlot.home, builder: _noop),
        UiContribution(slot: UiSlot.drawer, builder: _noop),
      ]));
      final descs = registry.getFeatureContributionDescriptors('a');
      expect(descs.length, 2);
      expect(descs.map((d) => d.key), ['home::a::0', 'drawer::a::1']);
    });
  });

  group('validateAll', () {
    test('empty map when all dependencies present and compatible', () {
      registry.addFeature(_TestFeature('dep'));
      registry.addFeature(_TestFeature('a', deps: ['dep']));
      expect(registry.validateAll(), isEmpty);
    });

    test('reports a missing dependency', () {
      registry.addFeature(_TestFeature('a', deps: ['missing']));
      final errors = registry.validateAll();
      expect(errors.containsKey('a'), isTrue);
      expect(errors['a'], contains('missing'));
    });

    test('reports a compatibility error', () {
      registry.addFeature(_TestFeature('a', compatError: 'too old'));
      expect(registry.validateAll()['a'], 'too old');
    });
  });

  group('initializeAll', () {
    test('initializes enabled features and registers their surfaces', () async {
      var initialized = false;
      registry.addFeature(_TestFeature(
        'a',
        onInit: () => initialized = true,
        roles: const [RoleDefinition(key: 'r', label: 'R')],
        settings: const [
          UserSettingDefinition(key: 's', label: 'S', defaultValue: 1)
        ],
        widgets: {'w': (_) => const SizedBox()},
        extensions: [_FakeUserDataExt('ext')],
      ));
      await registry.initializeAll();
      expect(initialized, isTrue);
      expect(registry.roleRegistry.allDefinitions.single.key, 'r');
      expect(registry.settingsRegistry.allDefinitions.single.key, 's');
      expect(registry.widgetRegistry.contains('w'), isTrue);
      expect(registry.userDataExtensions.length, 1);
    });

    test('throws StateError when validation fails', () async {
      registry.addFeature(_TestFeature('a', deps: ['missing']));
      expect(registry.initializeAll(), throwsStateError);
    });

    test('does not initialize a disabled feature', () async {
      var initialized = false;
      registry.addFeature(_TestFeature('a', onInit: () => initialized = true));
      registry.setDisabledFeatures({'a'});
      await registry.initializeAll();
      expect(initialized, isFalse);
    });
  });

  group('aggregateTranslations', () {
    final base = {
      'en': {'common.ok': 'OK'},
    };

    test('merges base with feature translations', () {
      registry.addFeature(_TestFeature('a', translations: {
        'en': {'a.title': 'Title'},
        'ar': {'a.title': 'عنوان'},
      }));
      final merged = registry.aggregateTranslations(base);
      expect(merged['en']!['common.ok'], 'OK');
      expect(merged['en']!['a.title'], 'Title');
      expect(merged['ar']!['a.title'], 'عنوان');
    });

    test('result is cached (same instance on repeat call)', () {
      registry.addFeature(_TestFeature('a', translations: {
        'en': {'a.title': 'Title'},
      }));
      final first = registry.aggregateTranslations(base);
      final second = registry.aggregateTranslations(base);
      expect(identical(first, second), isTrue);
    });

    test('invalidateTranslations forces a rebuild', () {
      registry.addFeature(_TestFeature('a', translations: {
        'en': {'a.title': 'Title'},
      }));
      final first = registry.aggregateTranslations(base);
      registry.invalidateTranslations();
      final second = registry.aggregateTranslations(base);
      expect(identical(first, second), isFalse);
    });

    test('setDisabledFeatures invalidates the cache', () {
      registry.addFeature(_TestFeature('a', translations: {
        'en': {'a.title': 'Title'},
      }));
      final first = registry.aggregateTranslations(base);
      expect(first['en']!.containsKey('a.title'), isTrue);
      registry.setDisabledFeatures({'a'});
      final second = registry.aggregateTranslations(base);
      expect(second['en']!.containsKey('a.title'), isFalse);
    });

    test('merged result is deeply unmodifiable', () {
      final merged = registry.aggregateTranslations(base);
      expect(() => merged['en']!['x'] = 'y', throwsUnsupportedError);
    });
  });

  group('user data distribution', () {
    test('distributeUserData routes section by key + roles + settings', () {
      final ext = _FakeUserDataExt('social');
      registry.addFeature(_TestFeature(
        'a',
        extensions: [ext],
        roles: const [RoleDefinition(key: 'agency.agent', label: 'Agent')],
        settings: const [
          UserSettingDefinition(key: 'privacy.h', label: 'H', defaultValue: false)
        ],
      ));
      return registry.initializeAll().then((_) {
        registry.distributeUserData({
          'social': {'fans': 5},
          'roles': ['agency.agent'],
          'settings': {'privacy.h': true},
        });
        expect(ext.received, {'fans': 5});
        expect(registry.roleRegistry.hasRole('agency.agent'), isTrue);
        expect(registry.settingsRegistry.getValue<bool>('privacy.h'), isTrue);
      });
    });

    test('clearAllUserData clears extensions/roles/settings', () async {
      final ext = _FakeUserDataExt('social');
      registry.addFeature(_TestFeature('a', extensions: [ext]));
      await registry.initializeAll();
      registry.roleRegistry.setUserRoles(['x']);
      registry.settingsRegistry.setValue('k', 1);
      registry.clearAllUserData();
      expect(ext.cleared, isTrue);
      expect(registry.roleRegistry.userRoleKeys, isEmpty);
      expect(registry.settingsRegistry.allValues, isEmpty);
    });

    test('serializeAllUserData gathers extension data + roles + settings', () async {
      final ext = _FakeUserDataExt('social')..toSerialize = {'fans': 9};
      registry.addFeature(_TestFeature('a', extensions: [ext]));
      await registry.initializeAll();
      registry.roleRegistry.setUserRoles(['r1']);
      registry.settingsRegistry.setValue('s1', true);
      final out = registry.serializeAllUserData();
      expect(out['social'], {'fans': 9});
      expect(out['roles'], ['r1']);
      expect(out['settings'], {'s1': true});
    });
  });

  group('clear', () {
    test('removes features, widgets, extensions and order overrides', () {
      registry.addFeature(_TestFeature('a',
          contributions: [UiContribution(slot: UiSlot.home, builder: _noop)],
          widgets: {'w': (_) => const SizedBox()}));
      registry.widgetRegistry.register('manual', (_) => const SizedBox());
      registry.clear();
      expect(registry.allFeatures, isEmpty);
      expect(registry.widgetRegistry.registeredWidgets, isEmpty);
      expect(registry.userDataExtensions, isEmpty);
    });
  });
}
