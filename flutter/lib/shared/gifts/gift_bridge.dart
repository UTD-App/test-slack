import 'package:flutter/widgets.dart';

/// How the Gifts package opens its picker. Receives the context the gift is
/// sent in (e.g. a moment) so the picker can post to the right endpoint, plus an
/// optional [onSent] the picker fires after a successful send so the host can
/// update its UI (e.g. bump the moment's gift count) without a full refresh.
typedef GiftLauncher = void Function(
  BuildContext context, {
  required String contextType,
  required int contextId,
  String? receiverName,
  VoidCallback? onSent,
});

/// Flutter analog of the backend `App\Contracts\GiftSender` seam.
///
/// A host feature (Moment, Reels…) lets a user send a gift WITHOUT depending on
/// the Gifts package: it calls [GiftBridge.instance.open]. The Gifts package
/// registers the launcher at startup ([register]). When Gifts isn't installed,
/// [isAvailable] is false and the host simply hides its gift button.
class GiftBridge {
  GiftBridge._();

  static final GiftBridge instance = GiftBridge._();

  GiftLauncher? _launcher;

  bool get isAvailable => _launcher != null;

  void register(GiftLauncher launcher) => _launcher = launcher;

  void open(
    BuildContext context, {
    required String contextType,
    required int contextId,
    String? receiverName,
    VoidCallback? onSent,
  }) {
    _launcher?.call(
      context,
      contextType: contextType,
      contextId: contextId,
      receiverName: receiverName,
      onSent: onSent,
    );
  }
}
