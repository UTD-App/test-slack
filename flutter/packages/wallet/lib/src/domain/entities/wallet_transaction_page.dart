import 'wallet_transaction.dart';

/// A page of ledger movements plus whether the server says more pages exist.
///
/// [hasMore] is `null` when the response carried no pagination `meta` (e.g. a
/// non-paginated/legacy endpoint), letting callers fall back to inferring it
/// from an empty page.
class WalletTransactionPage {
  final List<WalletTransaction> items;
  final bool? hasMore;

  const WalletTransactionPage(this.items, {this.hasMore});

  /// Returns a new page with [items] mapped through [transform], keeping [hasMore].
  WalletTransactionPage map(
    List<WalletTransaction> Function(List<WalletTransaction>) transform,
  ) =>
      WalletTransactionPage(transform(items), hasMore: hasMore);
}
