/// Translation keys + bundled values for the Wallet feature (coins only).
///
/// Usage in widgets: `context.tr(WalletStrings.title)`.
/// The [translations] map is merged into the app's translation table by
/// `WalletFeature.getTranslations()` — admin/server overrides win automatically.
class WalletStrings {
  WalletStrings._();

  // ── Keys (use these with context.tr) ───────────────────
  static const title = 'wallet.title';
  static const coins = 'wallet.coins';

  // Transactions
  static const transactions = 'wallet.transactions';
  static const noTransactions = 'wallet.no_transactions';
  static const filter = 'wallet.filter';
  static const clearFilter = 'wallet.clear_filter';

  // Misc
  static const somethingWrong = 'wallet.something_wrong';
  static const retry = 'wallet.retry';

  // ── Bundled values ─────────────────────────────────────
  static Map<String, Map<String, String>> translations() => {
        'en': {
          title: 'Wallet',
          coins: 'Coins',
          transactions: 'Transactions',
          noTransactions: 'No transactions yet',
          filter: 'Filter',
          clearFilter: 'Clear',
          somethingWrong: 'Something went wrong',
          retry: 'Retry',
        },
        'ar': {
          title: 'المحفظة',
          coins: 'كوينز',
          transactions: 'المعاملات',
          noTransactions: 'لا توجد معاملات بعد',
          filter: 'تصفية',
          clearFilter: 'مسح',
          somethingWrong: 'حدث خطأ ما',
          retry: 'إعادة المحاولة',
        },
      };
}
