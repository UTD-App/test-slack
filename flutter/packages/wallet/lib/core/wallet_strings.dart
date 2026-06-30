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

  // Transaction-type labels (keyed `wallet.tx_type.<enum value>`). Mirrors the
  // backend `CoinTransactionType` enum + the `admin_deduct` reason used by
  // ChargeService. The transaction tile looks up `wallet.tx_type.$type` and
  // falls back to the humanized type/reason when a key is missing, so new/unknown
  // backend types still render.
  static String txType(String value) => 'wallet.tx_type.$value';

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
          // Transaction types
          'wallet.tx_type.admin_charge': 'Admin charge',
          'wallet.tx_type.admin_deduct': 'Admin deduction',
          'wallet.tx_type.area_manager_charge': 'Area manager charge',
          'wallet.tx_type.bd_charge': 'BD charge',
          'wallet.tx_type.app_charge': 'In-app charge',
          'wallet.tx_type.return_charge': 'Charge reversal',
          'wallet.tx_type.payment': 'Payment',
          'wallet.tx_type.google_pay': 'Google Pay',
          'wallet.tx_type.huawei_pay': 'Huawei Pay',
          'wallet.tx_type.exchange': 'Exchange',
          'wallet.tx_type.gift': 'Gift',
          'wallet.tx_type.lucky_gift': 'Lucky gift',
          'wallet.tx_type.cashback': 'Cashback',
          'wallet.tx_type.daily_gift': 'Daily gift',
          'wallet.tx_type.room_target': 'Room target',
          'wallet.tx_type.room_level': 'Room level',
          'wallet.tx_type.create_room': 'Create room',
          'wallet.tx_type.room_comment': 'Room comment',
          'wallet.tx_type.coin_game': 'Coin game',
          'wallet.tx_type.lucky_box': 'Lucky box',
          'wallet.tx_type.pk': 'PK battle',
          'wallet.tx_type.super_admin_reward': 'Super admin reward',
          'wallet.tx_type.region_manager_reward': 'Region manager reward',
          'wallet.tx_type.admin_reward': 'Admin reward',
          'wallet.tx_type.room_boom': 'Room boom',
          'wallet.tx_type.room_cup': 'Room cup',
          'wallet.tx_type.host_level': 'Host level',
          'wallet.tx_type.weekly_star': 'Weekly star',
          'wallet.tx_type.milestone': 'Milestone',
          'wallet.tx_type.gift_ranking': 'Gift ranking',
          'wallet.tx_type.level_interval': 'Level reward',
          'wallet.tx_type.charge_event': 'Charge event',
          'wallet.tx_type.cp': 'CP reward',
          'wallet.tx_type.cps': 'CPS reward',
          'wallet.tx_type.invitation_code': 'Invitation code',
          'wallet.tx_type.invitation_charge_earnings': 'Invitation charge earnings',
          'wallet.tx_type.compensation': 'Compensation',
          'wallet.tx_type.remaining_diamonds': 'Remaining diamonds',
          'wallet.tx_type.vip': 'VIP',
          'wallet.tx_type.pack': 'Pack',
          'wallet.tx_type.family': 'Family',
          'wallet.tx_type.background_images': 'Background image',
          'wallet.tx_type.special_id': 'Special ID',
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
          // Transaction types
          'wallet.tx_type.admin_charge': 'شحن إداري',
          'wallet.tx_type.admin_deduct': 'خصم إداري',
          'wallet.tx_type.area_manager_charge': 'شحن مدير المنطقة',
          'wallet.tx_type.bd_charge': 'شحن BD',
          'wallet.tx_type.app_charge': 'شحن داخل التطبيق',
          'wallet.tx_type.return_charge': 'عكس شحنة',
          'wallet.tx_type.payment': 'دفع',
          'wallet.tx_type.google_pay': 'Google Pay',
          'wallet.tx_type.huawei_pay': 'Huawei Pay',
          'wallet.tx_type.exchange': 'تحويل',
          'wallet.tx_type.gift': 'هدية',
          'wallet.tx_type.lucky_gift': 'هدية الحظ',
          'wallet.tx_type.cashback': 'استرداد نقدي',
          'wallet.tx_type.daily_gift': 'هدية يومية',
          'wallet.tx_type.room_target': 'هدف الغرفة',
          'wallet.tx_type.room_level': 'مستوى الغرفة',
          'wallet.tx_type.create_room': 'إنشاء غرفة',
          'wallet.tx_type.room_comment': 'تعليق الغرفة',
          'wallet.tx_type.coin_game': 'لعبة الكوينز',
          'wallet.tx_type.lucky_box': 'صندوق الحظ',
          'wallet.tx_type.pk': 'معركة PK',
          'wallet.tx_type.super_admin_reward': 'مكافأة المشرف العام',
          'wallet.tx_type.region_manager_reward': 'مكافأة مدير الإقليم',
          'wallet.tx_type.admin_reward': 'مكافأة الإدارة',
          'wallet.tx_type.room_boom': 'انفجار الغرفة',
          'wallet.tx_type.room_cup': 'كأس الغرفة',
          'wallet.tx_type.host_level': 'مستوى المضيف',
          'wallet.tx_type.weekly_star': 'نجم الأسبوع',
          'wallet.tx_type.milestone': 'إنجاز',
          'wallet.tx_type.gift_ranking': 'ترتيب الهدايا',
          'wallet.tx_type.level_interval': 'مكافأة المستوى',
          'wallet.tx_type.charge_event': 'فعالية الشحن',
          'wallet.tx_type.cp': 'مكافأة CP',
          'wallet.tx_type.cps': 'مكافأة CPS',
          'wallet.tx_type.invitation_code': 'كود الدعوة',
          'wallet.tx_type.invitation_charge_earnings': 'أرباح شحن الدعوة',
          'wallet.tx_type.compensation': 'تعويض',
          'wallet.tx_type.remaining_diamonds': 'الألماس المتبقي',
          'wallet.tx_type.vip': 'VIP',
          'wallet.tx_type.pack': 'باقة',
          'wallet.tx_type.family': 'عائلة',
          'wallet.tx_type.background_images': 'صورة الخلفية',
          'wallet.tx_type.special_id': 'معرّف خاص',
        },
      };
}
