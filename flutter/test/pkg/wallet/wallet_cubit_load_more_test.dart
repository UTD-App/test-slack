import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:wallet/src/domain/entities/wallet_balance.dart';
import 'package:wallet/src/domain/entities/wallet_transaction.dart';
import 'package:wallet/src/domain/entities/wallet_transaction_page.dart';
import 'package:wallet/src/domain/repositories/wallet_repository.dart';
import 'package:wallet/src/presentation/bloc/wallet_cubit.dart';

WalletTransaction _tx(int id) => WalletTransaction(
      id: id,
      currency: 'coins',
      type: 'gift',
      direction: 'debit',
      amount: -1,
      absAmount: 1,
      balanceAfter: 0,
      reason: 'r',
      referenceType: null,
      createdAt: '',
    );

/// In-memory repository that serves a fixed set of pages, recording every
/// requested page so tests can assert the cubit's paging behavior.
class _FakeRepo implements WalletRepository {
  /// page (1-based) -> page payload.
  final Map<int, WalletTransactionPage> pages;
  final List<int> requestedPages = [];
  Result<WalletTransactionPage>? failNext;

  _FakeRepo(this.pages);

  @override
  Future<Result<List<WalletBalance>>> fetchBalances() async =>
      Result.success(const []);

  @override
  Future<Result<WalletTransactionPage>> fetchTransactions({
    String currency = 'coins',
    int page = 1,
    String? startDate,
    String? endDate,
    String? type,
  }) async {
    requestedPages.add(page);
    if (failNext != null) {
      final f = failNext!;
      failNext = null;
      return f;
    }
    return Result.success(
      pages[page] ?? const WalletTransactionPage([], hasMore: false),
    );
  }
}

void main() {
  group('WalletCubit load-more', () {
    test('first load sets page 1, hasMore from meta', () async {
      final repo = _FakeRepo({
        1: WalletTransactionPage([_tx(1), _tx(2)], hasMore: true),
      });
      final cubit = WalletCubit(repo);

      await cubit.loadTransactions();

      expect(repo.requestedPages, [1]);
      expect(cubit.state.transactions.map((t) => t.id), [1, 2]);
      expect(cubit.state.txPage, 1);
      expect(cubit.state.txHasMore, isTrue);
      expect(cubit.state.txStatus, WalletStatus.success);

      await cubit.close();
    });

    test('loadMore appends the next page and advances the page counter', () async {
      final repo = _FakeRepo({
        1: WalletTransactionPage([_tx(1), _tx(2)], hasMore: true),
        2: WalletTransactionPage([_tx(3), _tx(4)], hasMore: false),
      });
      final cubit = WalletCubit(repo);

      await cubit.loadTransactions();
      await cubit.loadMoreTransactions();

      expect(repo.requestedPages, [1, 2]);
      expect(cubit.state.transactions.map((t) => t.id), [1, 2, 3, 4]);
      expect(cubit.state.txPage, 2);
      expect(cubit.state.txHasMore, isFalse);
      expect(cubit.state.txLoadingMore, isFalse);

      await cubit.close();
    });

    test('loadMore is a no-op when there are no more pages', () async {
      final repo = _FakeRepo({
        1: WalletTransactionPage([_tx(1)], hasMore: false),
      });
      final cubit = WalletCubit(repo);

      await cubit.loadTransactions();
      await cubit.loadMoreTransactions();

      expect(repo.requestedPages, [1]); // page 2 never requested
      expect(cubit.state.transactions.map((t) => t.id), [1]);

      await cubit.close();
    });

    test('loadTransactions resets to page 1 after paging', () async {
      final repo = _FakeRepo({
        1: WalletTransactionPage([_tx(1)], hasMore: true),
        2: WalletTransactionPage([_tx(2)], hasMore: true),
      });
      final cubit = WalletCubit(repo);

      await cubit.loadTransactions();
      await cubit.loadMoreTransactions();
      expect(cubit.state.txPage, 2);

      await cubit.loadTransactions();
      expect(cubit.state.txPage, 1);
      expect(cubit.state.transactions.map((t) => t.id), [1]);
      expect(repo.requestedPages, [1, 2, 1]);

      await cubit.close();
    });

    test('loadMore failure keeps existing rows and stops the spinner', () async {
      final repo = _FakeRepo({
        1: WalletTransactionPage([_tx(1)], hasMore: true),
      });
      final cubit = WalletCubit(repo);

      await cubit.loadTransactions();
      repo.failNext = Result.failure('boom');
      await cubit.loadMoreTransactions();

      expect(cubit.state.transactions.map((t) => t.id), [1]); // preserved
      expect(cubit.state.txLoadingMore, isFalse);
      expect(cubit.state.error, 'boom');

      await cubit.close();
    });

    test('null meta hasMore on first load is treated as no-more', () async {
      final repo = _FakeRepo({
        1: const WalletTransactionPage([], hasMore: null),
      });
      final cubit = WalletCubit(repo);

      await cubit.loadTransactions();
      expect(cubit.state.txHasMore, isFalse);

      await cubit.close();
    });
  });
}
