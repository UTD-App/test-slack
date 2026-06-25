import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

import '../core/studio_slot_registry.dart';

/// Renders a `utdSlot` placeholder: a named insertion point the screen author
/// drops where package contributions should appear.
///
/// ```json
/// { "type": "utdSlot", "slot": "profile.cards" }
/// ```
///
/// At build time it expands to a column of every Stac node registered for that
/// slot via [StudioSlotRegistry.contributeToSlot] (empty → renders nothing). The
/// complement is [StudioSlotRegistry.contributeScreenCard], which appends to a
/// screen's main column without the author placing any node.
class StacUtdSlotParser extends StacParser<Map<String, dynamic>> {
  const StacUtdSlotParser();

  @override
  String get type => 'utdSlot';

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;

  @override
  Widget parse(BuildContext context, Map<String, dynamic> model) {
    final slot = model['slot'] as String?;
    if (slot == null || slot.isEmpty) return const SizedBox.shrink();

    final fragments = StudioSlotRegistry.instance.fragmentsFor(slot);
    if (fragments.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final fragment in fragments)
          Stac.fromJson(fragment, context) ?? const SizedBox.shrink(),
      ],
    );
  }
}
