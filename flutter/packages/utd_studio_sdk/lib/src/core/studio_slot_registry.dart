import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Registry of server-driven screen *slot contributions* — extra Stac subtrees
/// that a package injects into a Studio screen it does **not** own (e.g. the
/// wallet's coin card on the profile screen). This is the Studio equivalent of
/// the native `UiSlot.userProfile`: the screen owner declares *where* (or just
/// owns the screen), and each installed package declares *what*.
///
/// Packages register from their `Feature.initialize`; the renderer
/// ([StacDynamicScreen]) injects the contributions at render time. So nothing is
/// ever pushed to the published screen on the server — installing a package makes
/// its card appear, disabling/uninstalling removes it, and the owner's screen is
/// never clobbered.
///
/// Two ways to contribute:
///  * [contributeScreenCard] — append a card to the END of a screen's main
///    column (the drop-in analogue of contributing to `UiSlot.userProfile`,
///    works on the existing published screen with no edit).
///  * [contributeToSlot] — fill a named `{ "type": "utdSlot", "slot": "<name>" }`
///    placeholder the screen author placed for precise positioning.
///
/// Registrations are keyed (slot + key) so re-running `initialize` (features are
/// built more than once during boot) overwrites rather than duplicates.
class StudioSlotRegistry {
  StudioSlotRegistry._();

  static final StudioSlotRegistry instance = StudioSlotRegistry._();

  /// slot → (registration key → Stac node). A `Map` value preserves insertion
  /// order, so contributions render in registration order, and a repeated key
  /// overwrites instead of appending a duplicate.
  final Map<String, Map<String, Map<String, dynamic>>> _slots = {};

  /// Reserved slot-name prefix for "append to this screen's main column" cards.
  static String _screenSlot(String screen) => 'screen:$screen';

  /// Append [node] to the main column of the screen named [screen] (e.g.
  /// `'profile'`). [key] uniquely identifies this contribution (e.g.
  /// `'wallet.coins'`) so it is registered once even if called repeatedly.
  void contributeScreenCard(
    String screen,
    String key,
    Map<String, dynamic> node,
  ) {
    contributeToSlot(_screenSlot(screen), key, node);
  }

  /// Register [node] under the named [slot], rendered wherever the screen places
  /// a `{ "type": "utdSlot", "slot": "<slot>" }` placeholder.
  void contributeToSlot(String slot, String key, Map<String, dynamic> node) {
    _slots.putIfAbsent(slot, () => {})[key] = node;
  }

  /// Stac nodes registered for [slot], in registration order (a fresh copy each
  /// call so callers can mutate freely).
  List<Map<String, dynamic>> fragmentsFor(String slot) {
    final entries = _slots[slot];
    if (entries == null || entries.isEmpty) return const [];
    return entries.values
        .map((n) => jsonDecode(jsonEncode(n)) as Map<String, dynamic>)
        .toList(growable: false);
  }

  /// Cards registered for the screen named [screen].
  List<Map<String, dynamic>> screenCards(String screen) =>
      fragmentsFor(_screenSlot(screen));

  /// Returns [content] (a screen body map `{ "body": … }`) with this screen's
  /// card contributions appended to its main column. The original is never
  /// mutated; when there is nothing to inject — or no main column is found — the
  /// input is returned unchanged so untouched screens pay zero cost.
  Map<String, dynamic> injectScreenSlots(
    String screenName,
    Map<String, dynamic> content,
  ) {
    final cards = screenCards(screenName);
    if (cards.isEmpty) return content;

    final copy = jsonDecode(jsonEncode(content)) as Map<String, dynamic>;
    final column = _findMainColumn(copy['body']);
    if (column == null) return content; // nowhere sensible to place → no-op.

    final children = (column['children'] as List?) ?? (column['children'] = []);
    children.addAll(cards);
    return copy;
  }

  /// Depth-first search for the outermost `column` node (the screen's main
  /// content column). Checks each node before its descendants, so the first hit
  /// is the top-level column, not a nested one.
  Map<String, dynamic>? _findMainColumn(dynamic node) {
    if (node is Map) {
      if (node['type'] == 'column' && node['children'] is List) {
        return node.cast<String, dynamic>();
      }
      for (final value in node.values) {
        final found = _findMainColumn(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final value in node) {
        final found = _findMainColumn(value);
        if (found != null) return found;
      }
    }
    return null;
  }

  @visibleForTesting
  void clear() => _slots.clear();
}
