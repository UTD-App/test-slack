/// Translation keys + bundled values for the Gifts feature.
/// Usage: `context.tr(GiftsStrings.send)`.
class GiftsStrings {
  GiftsStrings._();

  static const title = 'gifts.title';
  static const send = 'gifts.send';
  static const sendTo = 'gifts.send_to';
  static const quantity = 'gifts.quantity';
  static const quantityHint = 'gifts.quantity_hint';
  static const custom = 'gifts.custom';
  static const sent = 'gifts.sent';
  static const failed = 'gifts.failed';
  static const empty = 'gifts.empty';
  static const retry = 'gifts.retry';
  static const somethingWrong = 'gifts.something_wrong';
  static const unsupportedContext = 'gifts.unsupported_context';
  static const history = 'gifts.history';
  static const received = 'gifts.received';
  static const sentTab = 'gifts.sent_tab';
  static const noHistory = 'gifts.no_history';
  static const topSupporters = 'gifts.top_supporters';
  static const giftsSent = 'gifts.gifts_sent';

  static Map<String, Map<String, String>> translations() => {
        'en': {
          title: 'Gifts',
          send: 'Send',
          sendTo: 'Send to',
          quantity: 'Quantity',
          quantityHint: '1 – 9999',
          custom: 'Custom',
          sent: 'Gift sent',
          failed: 'Could not send the gift',
          empty: 'No gifts available',
          retry: 'Retry',
          somethingWrong: 'Something went wrong',
          unsupportedContext: 'This gift context is not supported',
          history: 'Gifts',
          received: 'Received',
          sentTab: 'Sent',
          noHistory: 'No gifts yet',
          topSupporters: 'Top supporters',
          giftsSent: 'Gifts sent',
        },
        'ar': {
          title: 'الهدايا',
          send: 'إرسال',
          sendTo: 'إرسال إلى',
          quantity: 'الكمية',
          quantityHint: '1 – 9999',
          custom: 'مخصص',
          sent: 'تم إرسال الهدية',
          failed: 'تعذّر إرسال الهدية',
          empty: 'لا توجد هدايا',
          retry: 'إعادة المحاولة',
          somethingWrong: 'حدث خطأ ما',
          unsupportedContext: 'سياق الهدية هذا غير مدعوم',
          history: 'الهدايا',
          received: 'المستلمة',
          sentTab: 'المُرسلة',
          noHistory: 'لا توجد هدايا بعد',
          topSupporters: 'الداعمون',
          giftsSent: 'الهدايا المرسلة',
        },
      };
}
