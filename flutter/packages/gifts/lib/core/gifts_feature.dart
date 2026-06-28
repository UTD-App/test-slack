import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:utd_app/addons/addons.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/gifts/gift_bridge.dart';

import '../src/data/datasources/gift_api_service.dart';
import '../src/data/repositories/gift_repository_impl.dart';
import '../src/domain/repositories/gift_repository.dart';
import '../src/presentation/view/gift_picker_sheet.dart';
import '../src/presentation/view/gifts_profile_section.dart';
import 'gifts_routes.dart';
import 'gifts_strings.dart';

/// Gifts feature — catalog + send picker + history. Registering it wires the
/// GiftBridge so host features (Moment, Reels…) can open the picker without
/// depending on this package. Hidden when the backend "gifts" package is off.
class GiftsFeature extends AppFeature {
  late final GiftApiService _api;
  late final GiftRepositoryImpl _repository;

  @override
  String get id => 'com.utd.gifts';

  @override
  String get displayName => 'Gifts';

  @override
  Future<void> initialize() async {
    _api = GiftApiService();
    _repository = GiftRepositoryImpl(_api);

    // Gifts depend on a Wallet (currency) package. Until one is installed the
    // backend reports wallet=false; we then DON'T register the GiftBridge, so
    // host features (Moment, Reels…) hide their gift button. It auto-enables once
    // a Wallet package is installed (next launch). Errors default to hidden.
    if (!await _api.walletAvailable()) return;

    // Wire the host seam: now any feature can open the picker. Room gifting
    // passes roomId/ownerId/recipients; moment/reel leave them null.
    GiftBridge.instance.register((
      context, {
      required contextType,
      required contextId,
      receiverName,
      void Function(int coins)? onSent,
      roomId,
      ownerId,
      recipients,
    }) {
      showGiftPicker(
        context,
        repository: _repository,
        contextType: contextType,
        contextId: contextId,
        receiverName: receiverName,
        onSent: onSent,
        roomId: roomId,
        ownerId: ownerId,
        recipients: recipients,
      );
    });
  }

  @override
  List<SingleChildWidget> getProviders() => [
        Provider<GiftRepository>.value(value: _repository),
      ];

  @override
  List<GoRoute> getRoutes() => GiftsRoutes.routes();

  @override
  List<UiContribution> getUiContributions() => [
        UiContribution(
          slot: UiSlot.drawer,
          label: GiftsStrings.history,
          builder: (context) => ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: Text(context.tr(GiftsStrings.history)),
            onTap: () {
              Navigator.of(context).maybePop();
              context.push(GiftsRoutes.history);
            },
          ),
        ),
        // Gifts section on a profile: received-gifts wall + (visited-only) top
        // supporters and gifts-sent. The widget self-hides on the viewer's own
        // profile, so the own profile is left unchanged.
        UiContribution(
          slot: UiSlot.userProfile,
          label: 'Gifts',
          order: 2,
          builder: (context) => const GiftsProfileSection(),
        ),
      ];

  @override
  Map<String, Map<String, String>> getTranslations() => GiftsStrings.translations();
}
