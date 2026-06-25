import '../../domain/entities/wallet_balance.dart';

double _toDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

class WalletBalanceModel extends WalletBalance {
  const WalletBalanceModel({
    required super.currency,
    required super.balance,
    required super.available,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      currency: json['currency']?.toString() ?? '',
      balance: _toDouble(json['balance']),
      available: _toDouble(json['available']),
    );
  }
}
