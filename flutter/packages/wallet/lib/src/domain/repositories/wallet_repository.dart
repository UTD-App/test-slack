import 'package:utd_app/network/models/api_response.dart';

import '../entities/wallet_balance.dart';
import '../entities/wallet_transaction_page.dart';

/// Wallet data operations. Implementations wrap the API and return [Result].
abstract class WalletRepository {
  /// All balances for the current user (one per configured currency).
  Future<Result<List<WalletBalance>>> fetchBalances();

  /// One page of the ledger for a currency (newest first), with optional filters.
  ///
  /// Returns the page items plus the server's `has_more` flag (for load-more).
  /// [startDate] / [endDate] are `yyyy-MM-dd`; [type] filters by reason slug.
  Future<Result<WalletTransactionPage>> fetchTransactions({
    String currency = 'coins',
    int page = 1,
    String? startDate,
    String? endDate,
    String? type,
  });
}
