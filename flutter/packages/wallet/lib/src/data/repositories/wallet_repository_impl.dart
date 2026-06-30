import 'package:utd_app/network/models/api_response.dart';

import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction_page.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_api_service.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletApiService api;

  WalletRepositoryImpl(this.api);

  @override
  Future<Result<List<WalletBalance>>> fetchBalances() async {
    final res = await api.fetchBalances();
    return res.map((list) => list.cast<WalletBalance>());
  }

  @override
  Future<Result<WalletTransactionPage>> fetchTransactions({
    String currency = 'coins',
    int page = 1,
    String? startDate,
    String? endDate,
    String? type,
  }) async {
    return api.fetchTransactions(
      currency: currency,
      page: page,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
  }
}
