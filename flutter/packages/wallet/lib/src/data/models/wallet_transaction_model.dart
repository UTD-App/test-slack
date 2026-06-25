import '../../domain/entities/wallet_transaction.dart';

int _toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.currency,
    required super.type,
    required super.direction,
    required super.amount,
    required super.absAmount,
    required super.balanceAfter,
    required super.reason,
    required super.referenceType,
    required super.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final amount = _toDouble(json['amount']);
    // Be resilient if the backend ever omits `direction`.
    final direction =
        json['direction']?.toString() ?? (amount < 0 ? 'debit' : 'credit');
    final type = json['type']?.toString() ?? '';

    return WalletTransactionModel(
      id: _toInt(json['id']),
      currency: json['currency']?.toString() ?? '',
      type: type,
      direction: direction,
      amount: amount,
      absAmount: json['abs_amount'] != null ? _toDouble(json['abs_amount']) : amount.abs(),
      balanceAfter: _toDouble(json['balance_after']),
      reason: json['reason']?.toString() ?? type,
      referenceType: json['reference_type']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
