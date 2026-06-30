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

  /// 1-based page of the transactions currently loaded.
  final int txPage;

  /// Whether the server reports more transaction pages to fetch.
  final bool txHasMore;

  /// True while a load-more (next page) request is in flight.
  final bool txLoadingMore;

  const WalletState({
    this.balancesStatus = WalletStatus.initial,
    this.txStatus = WalletStatus.initial,
    this.balances = const [],
    this.transactions = const [],
    this.selectedCurrency = 'coins',
    this.startDate,
    this.endDate,
    this.error,
    this.txPage = 1,
    this.txHasMore = false,
    this.txLoadingMore = false,
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
    int? txPage,
    bool? txHasMore,
    bool? txLoadingMore,
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
      txPage: txPage ?? this.txPage,
      txHasMore: txHasMore ?? this.txHasMore,
      txLoadingMore: txLoadingMore ?? this.txLoadingMore,
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
        txPage,
        txHasMore,
        txLoadingMore,
      ];
}

class WalletCubit extends Cubit<WalletState> {
  final WalletRepository repository;

  WalletCubit(this.repository) : super(const WalletState());

  /// Load balances and the first page of transactions for the selected currency.
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

  /// (Re)load the FIRST page of transactions, replacing the current list.
  Future<void> loadTransactions() async {
    emit(state.copyWith(
      txStatus: WalletStatus.loading,
      txLoadingMore: false,
      error: null,
    ));
    final res = await repository.fetchTransactions(
      currency: state.selectedCurrency,
      page: 1,
      startDate: state.startDate,
      endDate: state.endDate,
    );
    res.when(
      success: (page) => emit(state.copyWith(
        txStatus: WalletStatus.success,
        transactions: page.items,
        txPage: 1,
        // null meta → infer "more" from a full-looking first page is not possible
        // here (no per_page known), so treat unknown as "no more" to avoid an
        // endless fetch loop; an empty/short page stops load-more anyway.
        txHasMore: page.hasMore ?? false,
      )),
      failure: (msg, _) =>
          emit(state.copyWith(txStatus: WalletStatus.failure, error: msg)),
    );
  }

  /// Append the next page of transactions (infinite scroll). No-op when there
  /// are no more pages, a load-more is already running, or the first page is
  /// still loading.
  Future<void> loadMoreTransactions() async {
    if (!state.txHasMore ||
        state.txLoadingMore ||
        state.txStatus == WalletStatus.loading) {
      return;
    }

    final nextPage = state.txPage + 1;
    emit(state.copyWith(txLoadingMore: true, error: null));

    final res = await repository.fetchTransactions(
      currency: state.selectedCurrency,
      page: nextPage,
      startDate: state.startDate,
      endDate: state.endDate,
    );
    res.when(
      success: (page) => emit(state.copyWith(
        txLoadingMore: false,
        transactions: [...state.transactions, ...page.items],
        txPage: nextPage,
        // Prefer the server flag; fall back to "an empty page means no more".
        txHasMore: page.hasMore ?? page.items.isNotEmpty,
      )),
      // Keep the already-loaded rows; just stop the spinner and surface the error.
      failure: (msg, _) =>
          emit(state.copyWith(txLoadingMore: false, error: msg)),
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
