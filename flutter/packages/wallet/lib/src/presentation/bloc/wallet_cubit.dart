import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';

enum WalletStatus { initial, loading, success, failure }

class WalletState extends Equatable {
  final WalletStatus balancesStatus;
  final WalletStatus txStatus;
  final List<WalletBalance> balances;
  final List<WalletTransaction> transactions;

  /// Currency whose transactions are currently shown (coins only for now).
  final String selectedCurrency;
  final String? startDate; // yyyy-MM-dd
  final String? endDate; // yyyy-MM-dd
  final String? error;

  const WalletState({
    this.balancesStatus = WalletStatus.initial,
    this.txStatus = WalletStatus.initial,
    this.balances = const [],
    this.transactions = const [],
    this.selectedCurrency = 'coins',
    this.startDate,
    this.endDate,
    this.error,
  });

  /// Balance for a currency (zero if the user has none).
  WalletBalance balanceFor(String currency) => balances.firstWhere(
        (b) => b.currency == currency,
        orElse: () => WalletBalance.zero(currency),
      );

  bool get hasDateFilter => startDate != null || endDate != null;

  WalletState copyWith({
    WalletStatus? balancesStatus,
    WalletStatus? txStatus,
    List<WalletBalance>? balances,
    List<WalletTransaction>? transactions,
    String? selectedCurrency,
    String? startDate,
    String? endDate,
    bool clearDates = false,
    String? error,
  }) {
    return WalletState(
      balancesStatus: balancesStatus ?? this.balancesStatus,
      txStatus: txStatus ?? this.txStatus,
      balances: balances ?? this.balances,
      transactions: transactions ?? this.transactions,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        balancesStatus,
        txStatus,
        balances,
        transactions,
        selectedCurrency,
        startDate,
        endDate,
        error,
      ];
}

class WalletCubit extends Cubit<WalletState> {
  final WalletRepository repository;

  WalletCubit(this.repository) : super(const WalletState());

  /// Load balances and the transactions for the selected currency.
  Future<void> loadAll() async {
    await Future.wait([loadBalances(), loadTransactions()]);
  }

  Future<void> loadBalances() async {
    emit(state.copyWith(balancesStatus: WalletStatus.loading, error: null));
    final res = await repository.fetchBalances();
    res.when(
      success: (list) =>
          emit(state.copyWith(balancesStatus: WalletStatus.success, balances: list)),
      failure: (msg, _) =>
          emit(state.copyWith(balancesStatus: WalletStatus.failure, error: msg)),
    );
  }

  Future<void> loadTransactions() async {
    emit(state.copyWith(txStatus: WalletStatus.loading, error: null));
    final res = await repository.fetchTransactions(
      currency: state.selectedCurrency,
      startDate: state.startDate,
      endDate: state.endDate,
    );
    res.when(
      success: (list) =>
          emit(state.copyWith(txStatus: WalletStatus.success, transactions: list)),
      failure: (msg, _) =>
          emit(state.copyWith(txStatus: WalletStatus.failure, error: msg)),
    );
  }

  Future<void> setDateRange(String startDate, String endDate) async {
    emit(state.copyWith(startDate: startDate, endDate: endDate));
    await loadTransactions();
  }

  Future<void> clearDateFilter() async {
    if (!state.hasDateFilter) return;
    emit(state.copyWith(clearDates: true));
    await loadTransactions();
  }
}
