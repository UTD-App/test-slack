import 'package:equatable/equatable.dart';

/// A single ledger movement (credit or debit) on one wallet.
///
/// Mirrors the flat payload from the backend `GET /wallet/transactions`.
class WalletTransaction extends Equatable {
  final int id;
  final String currency;

  /// Free-form reason slug (e.g. `admin_charge`, `gift`, `payout`).
  final String type;

  /// `credit` or `debit`.
  final String direction;

  /// Signed amount (negative for debits).
  final double amount;

  /// Absolute amount, always positive.
  final double absAmount;

  /// Balance right after this movement.
  final double balanceAfter;

  /// Human-friendly reason (meta.reason or the type).
  final String reason;

  /// Short class name of the source model, if any (e.g. `Charge`).
  final String? referenceType;

  /// ISO-8601 timestamp string.
  final String createdAt;

  const WalletTransaction({
    required this.id,
    required this.currency,
    required this.type,
    required this.direction,
    required this.amount,
    required this.absAmount,
    required this.balanceAfter,
    required this.reason,
    required this.referenceType,
    required this.createdAt,
  });

  bool get isCredit => direction == 'credit';

  @override
  List<Object?> get props => [id];
}
