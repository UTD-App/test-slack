import 'package:equatable/equatable.dart';

/// One wallet balance for a single currency (e.g. coins or dollar).
///
/// `available = balance − held` (held is reserved for pending withdrawals;
/// for coins it is always 0).
class WalletBalance extends Equatable {
  final String currency;
  final double balance;
  final double available;

  const WalletBalance({
    required this.currency,
    required this.balance,
    required this.available,
  });

  /// A zero balance for a currency the user has never used.
  factory WalletBalance.zero(String currency) =>
      WalletBalance(currency: currency, balance: 0, available: 0);

  @override
  List<Object?> get props => [currency, balance, available];
}
