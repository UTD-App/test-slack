import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/network/services/base_api_service.dart';

import '../../domain/entities/wallet_transaction_page.dart';
import '../models/wallet_balance_model.dart';
import '../models/wallet_transaction_model.dart';

/// Talks to the backend `utd/wallet` package endpoints.
///
/// Backend wraps every response as `{ status, message, data, meta }`. `balances`
/// returns `data: [...]`; `transactions` returns a paginator at
/// `data: { data: [...], current_page, ... }` plus a `meta` block
/// (`current_page`/`last_page`/`has_more`).
class WalletApiService extends BaseApiService {
  /// Unwraps a list from either a plain `data: [...]` envelope or a paginator
  /// envelope `data: { data: [...] }`.
  static List<Map<String, dynamic>> _items(dynamic body) {
    var data = body is Map ? body['data'] : body;
    if (data is Map && data['data'] is List) {
      data = data['data']; // unwrap the paginator
    }
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  static int? _asInt(dynamic v) =>
      v is int ? v : (v is String ? int.tryParse(v) : null);

  /// Reads "are there more pages?" from the backend pagination `meta` block.
  ///
  /// Prefers the explicit `meta.has_more` flag; otherwise derives it from
  /// `meta.current_page < meta.last_page`. Returns `null` when no usable meta is
  /// present so the caller can fall back to empty-page inference.
  static bool? _hasMore(dynamic body) {
    if (body is! Map) return null;
    final meta = body['meta'];
    if (meta is! Map) return null;

    final hm = meta['has_more'];
    if (hm is bool) return hm;
    if (hm == 1 || hm == '1' || hm == 'true') return true;
    if (hm == 0 || hm == '0' || hm == 'false') return false;

    final current = _asInt(meta['current_page']);
    final last = _asInt(meta['last_page']);
    if (current != null && last != null) return current < last;

    return null;
  }

  Future<Result<List<WalletBalanceModel>>> fetchBalances() {
    return get<List<WalletBalanceModel>>(
      '/wallet/balances',
      fromJson: (body) => _items(body).map(WalletBalanceModel.fromJson).toList(),
    );
  }

  Future<Result<WalletTransactionPage>> fetchTransactions({
    String currency = 'coins',
    int page = 1,
    String? startDate,
    String? endDate,
    String? type,
  }) {
    return get<WalletTransactionPage>(
      '/wallet/transactions',
      queryParameters: {
        'currency': currency,
        'page': page,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (type != null) 'type': type,
      },
      fromJson: (body) => WalletTransactionPage(
        _items(body).map(WalletTransactionModel.fromJson).toList(),
        hasMore: _hasMore(body),
      ),
    );
  }
}
