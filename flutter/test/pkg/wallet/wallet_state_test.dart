import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/src/domain/entities/wallet_balance.dart';
import 'package:wallet/src/domain/entities/wallet_transaction.dart';
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

void main() {
  group('WalletState defaults', () {
    test('initial values', () {
      const s = WalletState();
      expect(s.balancesStatus, WalletStatus.initial);
      expect(s.txStatus, WalletStatus.initial);
      expect(s.balances, isEmpty);
      expect(s.transactions, isEmpty);
      expect(s.selectedCurrency, 'coins');
      expect(s.startDate, isNull);
      expect(s.endDate, isNull);
      expect(s.error, isNull);
      expect(s.hasDateFilter, isFalse);
    });
  });

  group('WalletState.balanceFor', () {
    test('returns the matching balance', () {
      const s = WalletState(
        balances: [
          WalletBalance(currency: 'coins', balance: 100, available: 100),
          WalletBalance(currency: 'dollar', balance: 5, available: 3),
        ],
      );
      expect(s.balanceFor('dollar').balance, 5);
      expect(s.balanceFor('coins').available, 100);
    });

    test('returns a zero balance when currency is absent', () {
      const s = WalletState();
      final z = s.balanceFor('coins');
      expect(z.currency, 'coins');
      expect(z.balance, 0);
      expect(z.available, 0);
    });
  });

  group('WalletState.hasDateFilter', () {
    test('true when only startDate set', () {
      const s = WalletState(startDate: '2026-01-01');
      expect(s.hasDateFilter, isTrue);
    });
    test('true when only endDate set', () {
      const s = WalletState(endDate: '2026-01-31');
      expect(s.hasDateFilter, isTrue);
    });
    test('true when both set', () {
      const s = WalletState(startDate: '2026-01-01', endDate: '2026-01-31');
      expect(s.hasDateFilter, isTrue);
    });
    test('false when neither set', () {
      expect(const WalletState().hasDateFilter, isFalse);
    });
  });

  group('WalletState.copyWith', () {
    test('overrides provided fields, preserves the rest', () {
      const base = WalletState(selectedCurrency: 'coins');
      final next = base.copyWith(
        balancesStatus: WalletStatus.success,
        balances: const [
          WalletBalance(currency: 'coins', balance: 1, available: 1),
        ],
        transactions: [_tx(1)],
      );
      expect(next.balancesStatus, WalletStatus.success);
      expect(next.balances.length, 1);
      expect(next.transactions.length, 1);
      expect(next.selectedCurrency, 'coins'); // preserved
      expect(next.txStatus, WalletStatus.initial); // preserved
    });

    test('sets start/end dates', () {
      final next = const WalletState()
          .copyWith(startDate: '2026-01-01', endDate: '2026-01-31');
      expect(next.startDate, '2026-01-01');
      expect(next.endDate, '2026-01-31');
      expect(next.hasDateFilter, isTrue);
    });

    test('clearDates wins over passed start/end dates', () {
      const base = WalletState(startDate: '2026-01-01', endDate: '2026-01-31');
      final next = base.copyWith(clearDates: true, startDate: '2030-01-01');
      expect(next.startDate, isNull);
      expect(next.endDate, isNull);
      expect(next.hasDateFilter, isFalse);
    });

    test('omitting dates preserves existing dates', () {
      const base = WalletState(startDate: '2026-01-01', endDate: '2026-01-31');
      final next = base.copyWith(txStatus: WalletStatus.loading);
      expect(next.startDate, '2026-01-01');
      expect(next.endDate, '2026-01-31');
    });

    test('error is always set to the passed value (reset when omitted)', () {
      // copyWith assigns `error: error` directly (no ?? this.error).
      final withError = const WalletState().copyWith(error: 'oops');
      expect(withError.error, 'oops');
      final cleared = withError.copyWith(txStatus: WalletStatus.success);
      expect(cleared.error, isNull);
    });
  });

  group('WalletState equality', () {
    test('equal when all props equal', () {
      const a = WalletState(selectedCurrency: 'coins');
      const b = WalletState(selectedCurrency: 'coins');
      expect(a, equals(b));
    });
    test('different selectedCurrency breaks equality', () {
      const a = WalletState(selectedCurrency: 'coins');
      const b = WalletState(selectedCurrency: 'dollar');
      expect(a, isNot(equals(b)));
    });
  });
}
