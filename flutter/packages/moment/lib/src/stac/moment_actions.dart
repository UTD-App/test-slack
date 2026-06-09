import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stac/stac.dart' hide StacService;
import 'package:utd_app/shared/stac/stac_data_registry.dart';

import 'moment_stac_sources.dart';

/// Stac action parsers for the moment feed. A UTD-Studio-designed feed screen
/// drives real behaviour through these: the editor only knows the `actionType`
/// (from the backend manifest `action_elements.produces`) — the logic lives
/// here, inside the package.
///
/// Base: the JSON map IS the model (no codegen). The base list parser injects
/// the pressed row under `item`, so item-scoped actions read their id from it.
abstract class _MomentMapAction extends StacActionParser<Map<String, dynamic>> {
  const _MomentMapAction();

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;

  /// The pressed list row, injected by the base list parser under `item`.
  Map<String, dynamic> _item(Map<String, dynamic> model) {
    final item = model['item'];
    return item is Map ? item.cast<String, dynamic>() : const {};
  }

  /// Read an int id from the row (falling back to the top-level model).
  int? _id(Map<String, dynamic> model, String key) {
    final raw = _item(model)[key] ?? model[key];
    return raw is int ? raw : int.tryParse('${raw ?? ''}');
  }
}

/// `moment.toggleLike` — like / unlike the pressed moment, then refresh the feed.
class MomentToggleLikeAction extends _MomentMapAction {
  const MomentToggleLikeAction();

  @override
  String get actionType => 'moment.toggleLike';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final id = _id(model, 'moment_id');
    final repo = MomentStacBridge.repository;
    if (id == null || repo == null) return;

    await repo.likeMoment(id);
    StacDataRegistry.instance.invalidate(); // bound widgets refetch fresh state
  }
}

/// `moment.open` — drill-down to the author's moments page.
class MomentOpenAction extends _MomentMapAction {
  const MomentOpenAction();

  @override
  String get actionType => 'moment.open';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final userId = _id(model, 'user_id');
    if (userId == null) return;
    context.push('/moment/user/$userId');
  }
}

/// The package's Stac action parsers, registered via [MomentFeature.getStacActionParsers].
List<StacActionParser> momentStacActionParsers() => const [
      MomentToggleLikeAction(),
      MomentOpenAction(),
    ];
