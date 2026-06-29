import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/src/data/models/wallet_balance_model.dart';
import 'package:wallet/src/data/models/wallet_transaction_model.dart';
import 'package:wallet/src/domain/entities/wallet_balance.dart';
import 'package:wallet/src/domain/entities/wallet_transaction.dart';

void main() {
  group('WalletBalanceModel.fromJson', () {
    test('parses a populated payload', () {
      final b = WalletBalanceModel.fromJson(const {
        'currency': 'coins',
        'balance': 1500.0,
        'available': 1200.0,
      });
      expect(b.currency, 'coins');
      expect(b.balance, 1500.0);
      expect(b.available, 1200.0);
      expect(b, isA<WalletBalance>());
    });

    test('defaults for empty payload', () {
      final b = WalletBalanceModel.fromJson(const {});
      expect(b.currency, '');
      expect(b.balance, 0.0);
      expect(b.available, 0.0);
    });

    test('coerces numeric values from int and string', () {
      final b = WalletBalanceModel.fromJson(const {
        'currency': 'dollar',
        'balance': 100, // int
        'available': '75.5', // string
      });
      expect(b.balance, 100.0);
      expect(b.available, 75.5);
    });

    test('unparseable numeric strings fall back to 0.0', () {
      final b = WalletBalanceModel.fromJson(const {'balance': 'NaN-ish'});
      expect(b.balance, 0.0);
    });
  });

  group('WalletBalance.zero', () {
    test('produces a zeroed balance for the given currency', () {
      final z = WalletBalance.zero('coins');
      expect(z.currency, 'coins');
      expect(z.balance, 0);
      expect(z.available, 0);
    });
  });

  group('WalletBalance equality', () {
    test('compares currency, balance and available (props)', () {
      const a = WalletBalance(currency: 'coins', balance: 1, available: 1);
      const b = WalletBalance(currency: 'coins', balance: 1, available: 1);
      const c = WalletBalance(currency: 'coins', balance: 2, available: 1);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('WalletTransactionModel.fromJson', () {
    test('parses a fully-populated payload', () {
      final t = WalletTransactionModel.fromJson(const {
        'id': 11,
        'currency': 'coins',
        'type': 'gift',
        'direction': 'debit',
        'amount': -50.0,
        'abs_amount': 50.0,
        'balance_after': 950.0,
        'reason': 'Sent a gift',
        'reference_type': 'Charge',
        'created_at': '2026-06-29T10:00:00Z',
      });
      expect(t.id, 11);
      expect(t.currency, 'coins');
      expect(t.type, 'gift');
      expect(t.direction, 'debit');
      expect(t.amount, -50.0);
      expect(t.absAmount, 50.0);
      expect(t.balanceAfter, 950.0);
      expect(t.reason, 'Sent a gift');
      expect(t.referenceType, 'Charge');
      expect(t.createdAt, '2026-06-29T10:00:00Z');
      expect(t.isCredit, isFalse);
      expect(t, isA<WalletTransaction>());
    });

    test('defaults for empty payload', () {
      final t = WalletTransactionModel.fromJson(const {});
      expect(t.id, 0);
      expect(t.currency, '');
      expect(t.type, '');
      expect(t.direction, 'credit'); // amount 0 -> not < 0 -> credit
      expect(t.amount, 0.0);
      expect(t.absAmount, 0.0);
      expect(t.balanceAfter, 0.0);
      expect(t.reason, ''); // falls back to type which is ''
      expect(t.referenceType, isNull);
      expect(t.createdAt, '');
    });

    group('direction inference when omitted', () {
      test('negative amount -> debit', () {
        final t = WalletTransactionModel.fromJson(const {'amount': -10.0});
        expect(t.direction, 'debit');
        expect(t.isCredit, isFalse);
      });
      test('positive amount -> credit', () {
        final t = WalletTransactionModel.fromJson(const {'amount': 10.0});
        expect(t.direction, 'credit');
        expect(t.isCredit, isTrue);
      });
      test('explicit direction overrides amount sign', () {
        final t = WalletTransactionModel.fromJson(
            const {'amount': 10.0, 'direction': 'debit'});
        expect(t.direction, 'debit');
      });
    });

    group('abs_amount fallback', () {
      test('uses amount.abs() when abs_amount omitted', () {
        final t = WalletTransactionModel.fromJson(const {'amount': -42.0});
        expect(t.absAmount, 42.0);
      });
      test('uses provided abs_amount when present', () {
        final t = WalletTransactionModel.fromJson(
            const {'amount': -42.0, 'abs_amount': 99.0});
        expect(t.absAmount, 99.0);
      });
    });

    test('reason falls back to type when reason omitted', () {
      final t = WalletTransactionModel.fromJson(const {'type': 'payout'});
      expect(t.reason, 'payout');
    });

    test('coerces id and doubles from strings', () {
      final t = WalletTransactionModel.fromJson(const {
        'id': '7',
        'amount': '12.5',
        'balance_after': '100',
      });
      expect(t.id, 7);
      expect(t.amount, 12.5);
      expect(t.balanceAfter, 100.0);
    });
  });

  group('WalletTransaction.isCredit', () {
    test('true only for direction == credit', () {
      const credit = WalletTransaction(
        id: 1,
        currency: 'coins',
        type: 't',
        direction: 'credit',
        amount: 1,
        absAmount: 1,
        balanceAfter: 1,
        reason: 'r',
        referenceType: null,
        createdAt: '',
      );
      const debit = WalletTransaction(
        id: 2,
        currency: 'coins',
        type: 't',
        direction: 'debit',
        amount: -1,
        absAmount: 1,
        balanceAfter: 1,
        reason: 'r',
        referenceType: null,
        createdAt: '',
      );
      expect(credit.isCredit, isTrue);
      expect(debit.isCredit, isFalse);
    });
  });

  group('WalletTransaction equality', () {
    test('is identity-by-id (props == [id])', () {
      const a = WalletTransaction(
        id: 1,
        currency: 'coins',
        type: 'a',
        direction: 'credit',
        amount: 1,
        absAmount: 1,
        balanceAfter: 1,
        reason: 'a',
        referenceType: 'A',
        createdAt: 'x',
      );
      const b = WalletTransaction(
        id: 1,
        currency: 'dollar',
        type: 'b',
        direction: 'debit',
        amount: -9,
        absAmount: 9,
        balanceAfter: 0,
        reason: 'b',
        referenceType: 'B',
        createdAt: 'y',
      );
      expect(a, equals(b)); // same id
    });
  });
}
