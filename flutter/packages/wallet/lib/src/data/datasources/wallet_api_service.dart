import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/network/services/base_api_service.dart';

import '../models/wallet_balance_model.dart';
import '../models/wallet_transaction_model.dart';

/// Talks to the backend `utd/wallet` package endpoints.
///
/// Backend wraps every response as `{ status, message, data }`. `balances`
/// returns `data: [...]`; `transactions` returns a paginator at
/// `data: { data: [...], current_page, ... }`.
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

  Future<Result<List<WalletBalanceModel>>> fetchBalances() {
    return get<List<WalletBalanceModel>>(
      '/wallet/balances',
      fromJson: (body) => _items(body).map(WalletBalanceModel.fromJson).toList(),
    );
  }

  Future<Result<List<WalletTransactionModel>>> fetchTransactions({
    String currency = 'coins',
    int page = 1,
    String? startDate,
    String? endDate,
    String? type,
  }) {
    return get<List<WalletTransactionModel>>(
      '/wallet/transactions',
      queryParameters: {
        'currency': currency,
        'page': page,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (type != null) 'type': type,
      },
      fromJson: (body) => _items(body).map(WalletTransactionModel.fromJson).toList(),
    );
  }
}
