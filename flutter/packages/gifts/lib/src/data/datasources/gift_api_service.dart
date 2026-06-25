import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/network/services/base_api_service.dart';

import '../models/gift_category_model.dart';
import '../models/gift_history_item_model.dart';
import '../models/gift_model.dart';

/// Talks to the backend `utd/gifts` endpoints (read-side) and posts gift sends
/// to the HOST feature's endpoint (resolved from the context type).
class GiftApiService extends BaseApiService {
  static List<Map<String, dynamic>> _items(dynamic body) {
    var data = body is Map ? body['data'] : body;
    if (data is Map && data['data'] is List) {
      data = data['data']; // paginator envelope
    }
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  static bool _status(dynamic body) {
    if (body is Map) {
      final s = body['status'];
      return s == true || s == 1 || s == '1';
    }
    return true;
  }

  /// Cache key for the last DEFINITIVE wallet-capability answer. Persisted so a
  /// transient network failure on a later cold start doesn't flip the gift UI
  /// off — we fall back to the last known answer instead of hiding it.
  static const String _walletFlagKey = 'gifts_wallet_available';

  /// How hard we try the startup capability check before giving up. Kept small
  /// because this runs inside the (sequential) feature init that blocks the
  /// app's "Initializing…" screen — see FeatureRegistry.initializeAll.
  static const int _walletCheckAttempts = 3;
  static const Duration _walletCheckTimeout = Duration(seconds: 10);
  static const Duration _walletCheckBackoff = Duration(milliseconds: 500);

  /// Whether gift sending is available — i.e. a Wallet (currency) package is
  /// installed. Reads the base `capabilities.wallet` flag from
  /// `/packages/installed` (a public endpoint), retrying a few times to ride out
  /// a cold/slow backend. The last definitive answer is cached; if EVERY attempt
  /// fails we fall back to it (default: hidden) so the gift UI doesn't flicker
  /// off on a transient blip rather than failing outright on send.
  Future<bool> walletAvailable() async {
    for (var attempt = 1; attempt <= _walletCheckAttempts; attempt++) {
      try {
        final res = await dio.get('/packages/installed').timeout(_walletCheckTimeout);
        final data = res.data is Map ? res.data['data'] : null;
        final caps = data is Map ? data['capabilities'] : null;
        final w = caps is Map ? caps['wallet'] : null;
        final available = w == true || w == 1 || w == '1';
        // Remember the definitive answer for the next cold start.
        await CacheManager.saveFlag(_walletFlagKey, available);
        return available;
      } catch (_) {
        // Transient (timeout / cold backend / blip) — back off and retry.
        if (attempt < _walletCheckAttempts) {
          await Future.delayed(_walletCheckBackoff);
        }
      }
    }
    // Every attempt failed: keep the last known answer instead of hiding the UI.
    return CacheManager.getFlag(_walletFlagKey) ?? false;
  }

  Future<Result<List<GiftCategoryModel>>> fetchCategories() {
    return get<List<GiftCategoryModel>>(
      '/gifts/categories',
      fromJson: (body) => _items(body).map(GiftCategoryModel.fromJson).toList(),
    );
  }

  Future<Result<List<GiftModel>>> fetchGifts({int? categoryId}) {
    return get<List<GiftModel>>(
      '/gifts',
      queryParameters: {if (categoryId != null) 'category_id': categoryId},
      fromJson: (body) => _items(body).map(GiftModel.fromJson).toList(),
    );
  }

  Future<Result<List<GiftHistoryItemModel>>> fetchHistory({String type = 'received', int page = 1}) {
    return get<List<GiftHistoryItemModel>>(
      '/gifts/history',
      queryParameters: {'type': type, 'page': page},
      fromJson: (body) => _items(body).map(GiftHistoryItemModel.fromJson).toList(),
    );
  }

  /// Maps a context type to its host send-endpoint and posts the gift.
  Future<Result<bool>> sendInContext({
    required String contextType,
    required int contextId,
    required int giftId,
    required int quantity,
  }) {
    final path = switch (contextType) {
      'moment' => '/moment/$contextId/gift',
      'real' || 'reel' => '/reals/$contextId/gift',
      _ => null,
    };

    if (path == null) {
      return Future.value(Result.failure('Unsupported gift context: $contextType'));
    }

    return post<bool>(
      path,
      data: {'gift_id': giftId, 'num': quantity},
      fromJson: _status,
    );
  }
}
