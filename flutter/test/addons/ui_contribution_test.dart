import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/addons/ui_contribution.dart';
import 'package:utd_app/addons/ui_slot.dart';

/// Pure-Dart tests for [UiSlot], [UiContribution] (incl. the bottomNav icon
/// assert) and [UiContributionDescriptor.label].
void main() {
  Widget noop(BuildContext _) => const SizedBox();

  group('UiSlot enum', () {
    test('has the expected members in declared order', () {
      expect(UiSlot.values, <UiSlot>[
        UiSlot.appBar,
        UiSlot.drawer,
        UiSlot.bottomNav,
        UiSlot.home,
        UiSlot.dashboard,
        UiSlot.settings,
        UiSlot.loginMethods,
        UiSlot.userProfile,
        UiSlot.userProfileActions,
        UiSlot.profileTab,
      ]);
    });

    test('names are stable (used as key prefixes)', () {
      expect(UiSlot.bottomNav.name, 'bottomNav');
      expect(UiSlot.userProfile.name, 'userProfile');
    });
  });

  group('UiContribution', () {
    test('defaults: order 0, null label/icons', () {
      final c = UiContribution(slot: UiSlot.home, builder: noop);
      expect(c.slot, UiSlot.home);
      expect(c.order, 0);
      expect(c.label, isNull);
      expect(c.activeIcon, isNull);
      expect(c.inactiveIcon, isNull);
    });

    test('retains supplied label and order', () {
      final c = UiContribution(
        slot: UiSlot.appBar,
        builder: noop,
        label: 'Settings',
        order: 5,
      );
      expect(c.label, 'Settings');
      expect(c.order, 5);
    });

    test('bottomNav requires both active and inactive icons', () {
      expect(
        () => UiContribution(slot: UiSlot.bottomNav, builder: noop),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => UiContribution(
          slot: UiSlot.bottomNav,
          builder: noop,
          activeIcon: const Icon(Icons.home),
          // inactiveIcon missing
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('bottomNav with both icons is valid', () {
      final c = UiContribution(
        slot: UiSlot.bottomNav,
        builder: noop,
        activeIcon: const Icon(Icons.home),
        inactiveIcon: const Icon(Icons.home_outlined),
      );
      expect(c.activeIcon, isNotNull);
      expect(c.inactiveIcon, isNotNull);
    });

    test('non-bottomNav slot needs no icons', () {
      expect(
        () => UiContribution(slot: UiSlot.drawer, builder: noop),
        returnsNormally,
      );
    });
  });

  group('UiContributionDescriptor', () {
    test('label uses the contribution label when present', () {
      final c = UiContribution(slot: UiSlot.home, builder: noop, label: 'Lbl');
      final d = UiContributionDescriptor(
        key: 'home::f::0',
        slot: UiSlot.home,
        featureId: 'f',
        featureName: 'Feature Name',
        contribution: c,
      );
      expect(d.label, 'Lbl');
    });

    test('label falls back to featureName when contribution label is null', () {
      final c = UiContribution(slot: UiSlot.home, builder: noop);
      final d = UiContributionDescriptor(
        key: 'home::f::0',
        slot: UiSlot.home,
        featureId: 'f',
        featureName: 'Feature Name',
        contribution: c,
      );
      expect(d.label, 'Feature Name');
    });
  });
}
