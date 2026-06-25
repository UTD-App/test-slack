import 'package:utd_app/network/models/api_response.dart';

import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
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
  Future<Result<List<WalletTransaction>>> fetchTransactions({
    String currency = 'coins',
    int page = 1,
    String? startDate,
    String? endDate,
    String? type,
  }) async {
    final res = await api.fetchTransactions(
      currency: currency,
      page: page,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
    return res.map((list) => list.cast<WalletTransaction>());
  }
}
