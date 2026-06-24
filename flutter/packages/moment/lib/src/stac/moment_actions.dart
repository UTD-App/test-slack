import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stac/stac.dart' hide StacService;
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/toast_manager.dart';
import 'package:utd_app/shared/gifts/gift_bridge.dart';
import 'package:utd_app/shared/stac/field_registry.dart';
import 'package:utd_app/shared/stac/stac_data_registry.dart';

import '../../core/moment_strings.dart';
import '../presentation/view/widgets/confirm_dialog.dart';
import '../presentation/view/widgets/report_moment_dialog.dart';
import 'moment_stac_sources.dart';

/// Stac action parsers for the moments screens. A UTD-Studio-designed feed/detail
/// screen drives real behaviour through these: the editor only knows the
/// `actionType` (from the backend manifest `action_elements.produces`) — the
/// logic lives here, inside the package.
///
/// Base: the JSON map IS the model (no codegen). The base list parser injects
/// the pressed row under `item` — both on a whole-row tap AND into per-row
/// buttons inside the item template — so item-scoped actions read their id from
/// it. The detail/comments screen targets a single moment via
/// [MomentStacBridge.currentMomentId], set by [MomentOpenAction].
abstract class _MomentMapAction extends StacActionParser<Map<String, dynamic>> {
  const _MomentMapAction();

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;

  /// The pressed row, injected by the base list parser under `item`.
  Map<String, dynamic> _item(Map<String, dynamic> model) {
    final item = model['item'];
    return item is Map ? item.cast<String, dynamic>() : const {};
  }

  /// Read an int from the row (falling back to the top-level model).
  int? _int(Map<String, dynamic> model, String key) {
    final raw = _item(model)[key] ?? model[key];
    return raw is int ? raw : int.tryParse('${raw ?? ''}');
  }

  String _str(Map<String, dynamic> model, String key) =>
      (_item(model)[key] ?? model[key] ?? '').toString();
}

/// `moment.toggleLike` — like / unlike the pressed moment, then refresh.
class MomentToggleLikeAction extends _MomentMapAction {
  const MomentToggleLikeAction();

  @override
  String get actionType => 'moment.toggleLike';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final id = _int(model, 'moment_id');
    final repo = MomentStacBridge.repository;
    if (id == null || repo == null) return;

    await repo.likeMoment(id);
    StacDataRegistry.instance.invalidate(); // bound widgets refetch fresh state
  }
}

/// `moment.open` — open the post detail screen (`/s/moment`). Stashes the pressed
/// row so the detail screen's `moment.detail` object source and `moment.comments`
/// list source resolve against it (the registry sources are context-free).
class MomentOpenAction extends _MomentMapAction {
  const MomentOpenAction();

  @override
  String get actionType => 'moment.open';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final row = _item(model);
    final id = _int(model, 'moment_id');
    if (id == null) return;

    MomentStacBridge.currentMoment = Map<String, dynamic>.from(row);
    MomentStacBridge.currentMomentId = id;
    StacDataRegistry.instance.invalidate();
    context.push('/s/moment');
  }
}

/// `moment.postMenu` — report / delete the pressed moment via a bottom sheet.
/// Delete is offered only when the row says the viewer owns it (`is_owner`).
class MomentPostMenuAction extends _MomentMapAction {
  const MomentPostMenuAction();

  @override
  String get actionType => 'moment.postMenu';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final id = _int(model, 'moment_id');
    final repo = MomentStacBridge.repository;
    if (id == null || repo == null) return;
    final isOwner =
        _item(model)['is_owner'] == true || model['is_owner'] == true;

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(ctx.tr(MomentStrings.report)),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(ctx.tr(MomentStrings.delete)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;

    if (choice == 'report') {
      final ok = await showReportMomentDialog(context, id);
      if (ok && context.mounted) {
        ToastManager.showToast(
          context,
          message: context.tr(MomentStrings.reportedThanks),
        );
      }
    } else if (choice == 'delete') {
      final confirm = await showThemedConfirm(
        context,
        title: context.tr(MomentStrings.deleteConfirm),
        confirmText: context.tr(MomentStrings.delete),
        cancelText: context.tr(MomentStrings.cancel),
        destructive: true,
      );
      if (confirm) {
        await repo.deleteMoment(id);
        StacDataRegistry.instance.invalidate();
        if (context.mounted) {
          ToastManager.showToast(
            context,
            message: context.tr(MomentStrings.deleted),
          );
        }
      }
    }
  }
}

/// `moment.sendGift` — open the gift picker for the pressed moment (only when the
/// Gifts package is installed and wired the [GiftBridge]).
class MomentSendGiftAction extends _MomentMapAction {
  const MomentSendGiftAction();

  @override
  String get actionType => 'moment.sendGift';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final id = _int(model, 'moment_id');
    if (id == null || !GiftBridge.instance.isAvailable) return;
    GiftBridge.instance.open(
      context,
      contextType: 'moment',
      contextId: id,
      receiverName: _str(model, 'user_name'),
    );
  }
}

/// `moment.addComment` — post the comment typed in the live field referenced by
/// `commentField`, on the currently-open moment, then refresh the comments list.
class MomentAddCommentAction extends _MomentMapAction {
  const MomentAddCommentAction();

  @override
  String get actionType => 'moment.addComment';

  @override
  Future<void> onCall(BuildContext context, Map<String, dynamic> model) async {
    final fieldId = (model['commentField'] as String?)?.trim();
    final momentId = MomentStacBridge.currentMomentId;
    final repo = MomentStacBridge.repository;
    if (fieldId == null || fieldId.isEmpty || momentId == null || repo == null)
      return;

    final controller = FieldRegistry.of(fieldId);
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final res = await repo.addComment(momentId, text);
    if (res.isSuccess) {
      controller.clear();
      StacDataRegistry.instance.invalidate(); // comments list refetches
    } else if (context.mounted) {
      ToastManager.showToast(
        context,
        message: context.tr(MomentStrings.somethingWrong),
        isError: true,
      );
    }
  }
}

/// The package's Stac action parsers, registered via [MomentFeature.getStacActionParsers].
List<StacActionParser> momentStacActionParsers() => const [
  MomentToggleLikeAction(),
  MomentOpenAction(),
  MomentPostMenuAction(),
  MomentSendGiftAction(),
  MomentAddCommentAction(),
];
