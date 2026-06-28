import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/gifts/gift_bridge.dart';
import 'package:utd_app/shared/media/dynamic_image.dart';

import '../../../core/gifts_strings.dart';
import '../../domain/entities/gift.dart';
import '../../domain/repositories/gift_repository.dart';
import '../bloc/gift_picker_cubit.dart';
import 'gift_play_overlay.dart';

/// Opens the gift picker as a modal bottom sheet for a given host context
/// (e.g. ('moment', 42)). Called by the GiftBridge launcher.
///
/// Room gifting passes [roomId]/[ownerId]/[recipients]: a recipient selector then
/// appears and the send goes to the chosen seats via /gifts/send. When
/// [recipients] is null/empty it behaves as before (single implicit receiver).
Future<void> showGiftPicker(
  BuildContext context, {
  required GiftRepository repository,
  required String contextType,
  required int contextId,
  String? receiverName,
  void Function(int coins)? onSent,
  int? roomId,
  int? ownerId,
  List<GiftRecipient>? recipients,
  RoomGiftSentCallback? onRoomGiftSent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => GiftPickerCubit(
        repository,
        roomId: roomId,
        ownerId: ownerId,
        recipients: recipients ?? const [],
      )..load(),
      child: GiftPickerSheet(
        contextType: contextType,
        contextId: contextId,
        receiverName: receiverName,
        onSent: onSent,
        onRoomGiftSent: onRoomGiftSent,
      ),
    ),
  );
}

class GiftPickerSheet extends StatelessWidget {
  final String contextType;
  final int contextId;
  final String? receiverName;

  /// Fired after a successful send with the total COINS sent, so the host (e.g. a
  /// moment card) can update its UI without reloading the whole feed.
  final void Function(int coins)? onSent;

  /// Fired after a successful ROOM send with the full gift details, so the room
  /// can broadcast it (RTM) + play the banner. Null/ignored for moment/reel.
  final RoomGiftSentCallback? onRoomGiftSent;

  const GiftPickerSheet({
    super.key,
    required this.contextType,
    required this.contextId,
    this.receiverName,
    this.onSent,
    this.onRoomGiftSent,
  });

  /// The gift currently selected in the picker (for the full-screen play).
  Gift? _selectedGift(GiftPickerState s) {
    for (final g in s.gifts) {
      if (g.id == s.selectedGiftId) return g;
    }
    return null;
  }

  Future<void> _send(BuildContext context) async {
    final cubit = context.read<GiftPickerCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Capture the ROOT overlay before the async gap / sheet pop so the gift
    // animation can play over the whole screen after this sheet closes.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    // Capture localized strings before the async gap (no context use after await).
    final sentMsg = context.tr(GiftsStrings.sent);
    final failedMsg = context.tr(GiftsStrings.failed);

    // Capture the gift + quantity BEFORE sending so we can report the coins spent
    // to the host for an instant UI update. In a room the sender pays for EACH
    // selected recipient (price × quantity × recipients).
    final sentGift = _selectedGift(cubit.state);
    final isRoom = cubit.isRoom;
    final giftNum = cubit.state.quantity;
    final recipientIds = cubit.state.selectedRecipientIds.toList();
    final recipientCount = isRoom ? recipientIds.length : 1;
    final coins = ((sentGift?.price ?? 0) * giftNum * recipientCount).round();

    final ok = await cubit.send(contextType: contextType, contextId: contextId);
    if (ok) {
      // Play the sent gift full-screen (its animation/image) over the host.
      if (overlay != null) {
        final src = (sentGift != null && sentGift.showImg.isNotEmpty) ? sentGift.showImg : (sentGift?.img ?? '');
        if (src.isNotEmpty) {
          GiftPlayOverlay.play(overlay, source: src, imageType: sentGift?.imageType ?? '');
        }
      }
      onSent?.call(coins);
      // Room sends also hand the full gift details to the host so it can RTM
      // broadcast + play the banner for everyone in the room.
      if (isRoom && onRoomGiftSent != null && sentGift != null) {
        onRoomGiftSent!(
          giftId: sentGift.id,
          giftName: sentGift.name,
          giftImg: sentGift.img,
          giftPrice: sentGift.price,
          giftNum: giftNum,
          recipientIds: recipientIds,
          totalCoins: coins,
        );
      }
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(sentMsg)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(failedMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: BlocBuilder<GiftPickerCubit, GiftPickerState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.card_giftcard, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        receiverName == null
                            ? context.tr(GiftsStrings.title)
                            : '${context.tr(GiftsStrings.sendTo)} ${receiverName!}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),

                // Recipients selector (room gifting only) — choose who on the
                // seats receives the gift; sends to all selected.
                if (state.recipients.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _RecipientsRow(
                    recipients: state.recipients,
                    selectedIds: state.selectedRecipientIds,
                    onToggle: (id) => context.read<GiftPickerCubit>().toggleRecipient(id),
                  ),
                ],

                // Category tabs
                if (state.categories.isNotEmpty)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = state.categories[i];
                        return ChoiceChip(
                          label: Text(cat.title),
                          selected: state.selectedCategoryId == cat.id,
                          onSelected: (_) => context.read<GiftPickerCubit>().selectCategory(cat.id),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),

                // Body
                SizedBox(height: 280, child: _Body(state: state)),

                // Quantity presets (×1 … ×9999 + custom)
                _QuantityPresets(
                  quantity: state.quantity,
                  onChanged: (q) => context.read<GiftPickerCubit>().setQuantity(q),
                ),
                const SizedBox(height: 10),

                // Send (full width, shows the selected quantity). In a room the
                // user must also pick at least one recipient.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (state.selectedGiftId == null ||
                            state.sending ||
                            (state.recipients.isNotEmpty && state.selectedRecipientIds.isEmpty))
                        ? null
                        : () => _send(context),
                    icon: state.sending
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: Text('${context.tr(GiftsStrings.send)}  ×${state.quantity}'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final GiftPickerState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (state.status == GiftPickerStatus.loading && state.gifts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == GiftPickerStatus.error && state.gifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error ?? context.tr(GiftsStrings.somethingWrong),
                style: TextStyle(color: colors.outline)),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => context.read<GiftPickerCubit>().load(),
              child: Text(context.tr(GiftsStrings.retry)),
            ),
          ],
        ),
      );
    }
    if (state.gifts.isEmpty) {
      return Center(child: Text(context.tr(GiftsStrings.empty), style: TextStyle(color: colors.outline)));
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: state.gifts.length,
      itemBuilder: (context, i) {
        final gift = state.gifts[i];
        final selected = state.selectedGiftId == gift.id;
        return _GiftTile(
          gift: gift,
          selected: selected,
          onTap: () => context.read<GiftPickerCubit>().selectGift(gift.id),
        );
      },
    );
  }
}

class _GiftTile extends StatelessWidget {
  final Gift gift;
  final bool selected;
  final VoidCallback onTap;

  const _GiftTile({required this.gift, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.primary : Colors.transparent, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              // DynamicImage picks the right renderer from the URL extension:
              // png/jpg/gif/webp → Image, .svg → flutter_svg, .svga → flutter_svga.
              // So a gift displays correctly whatever format it was uploaded in.
              child: gift.img.startsWith('http')
                  ? DynamicImage(
                      source: gift.img,
                      fit: BoxFit.contain,
                      placeholder: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: const Icon(Icons.card_giftcard, size: 28, color: Color(0xFFF5A623)),
                    )
                  : const Icon(Icons.card_giftcard, size: 28, color: Color(0xFFF5A623)),
            ),
            Text(gift.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, size: 12, color: Color(0xFFF5A623)),
                const SizedBox(width: 2),
                Text('${gift.price}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

/// Preset quantity picker — tap a chip (×1 … ×9999) or "Custom" to type a value.
/// Replaces the old +/- stepper. The cubit clamps to 1..9999.
class _QuantityPresets extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityPresets({required this.quantity, required this.onChanged});

  static const _presets = [1, 5, 9, 99, 999, 9999];

  @override
  Widget build(BuildContext context) {
    final isCustom = !_presets.contains(quantity);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i < _presets.length) {
            final q = _presets[i];
            return ChoiceChip(
              label: Text('×$q'),
              selected: quantity == q,
              onSelected: (_) => onChanged(q),
            );
          }
          return ChoiceChip(
            avatar: const Icon(Icons.edit, size: 16),
            label: Text(isCustom ? '×$quantity' : context.tr(GiftsStrings.custom)),
            selected: isCustom,
            onSelected: (_) => _promptCustom(context),
          );
        },
      ),
    );
  }

  Future<void> _promptCustom(BuildContext context) async {
    final controller = TextEditingController(text: '$quantity');
    final ml = MaterialLocalizations.of(context);
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr(GiftsStrings.quantity)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: '1 – 9999'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ml.cancelButtonLabel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: Text(ml.okButtonLabel),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }
}

/// Horizontal avatar selector for room gifting — tap to toggle who receives the
/// gift. Multiple seats can be selected; the send goes to all of them.
class _RecipientsRow extends StatelessWidget {
  final List<GiftRecipient> recipients;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  const _RecipientsRow({
    required this.recipients,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recipients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final r = recipients[i];
          final selected = selectedIds.contains(r.userId);
          final hasAvatar = r.avatar != null && r.avatar!.startsWith('http');

          return GestureDetector(
            onTap: () => onToggle(r.userId),
            child: SizedBox(
              width: 50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? colors.primary : colors.outlineVariant,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: colors.surfaceContainerHighest,
                          backgroundImage: hasAvatar ? NetworkImage(r.avatar!) : null,
                          child: hasAvatar
                              ? null
                              : Text(
                                  r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                            child: Icon(Icons.check, size: 12, color: colors.onPrimary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
