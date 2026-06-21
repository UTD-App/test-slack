import 'package:intl/intl.dart';

/// Shared date / number / currency formatters used across the whole app.
///
/// Thin wrappers over `intl` so features format consistently and don't each
/// re-declare patterns. Pass `locale` (e.g. the current `localeNotifier.locale
/// .languageCode`) to localize output; omit for the default locale.
class Formatters {
  Formatters._();

  // ── Dates ─────────────────────────────────────────────────────
  static String date(DateTime value, {String pattern = 'yyyy-MM-dd', String? locale}) =>
      DateFormat(pattern, locale).format(value);

  static String time(DateTime value, {String pattern = 'HH:mm', String? locale}) =>
      DateFormat(pattern, locale).format(value);

  static String dateTime(
    DateTime value, {
    String pattern = 'yyyy-MM-dd HH:mm',
    String? locale,
  }) =>
      DateFormat(pattern, locale).format(value);

  /// Compact "time ago" label. [now] is injectable for testing.
  /// Output is intentionally short (`just now`, `5m`, `3h`, `2d`); beyond a
  /// week it falls back to an absolute [date].
  static String relativeTime(DateTime value, {DateTime? now, String? locale}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(value);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return date(value, locale: locale);
  }

  // ── Numbers ───────────────────────────────────────────────────
  static String currency(
    num amount, {
    String symbol = '\$',
    int decimals = 2,
    String? locale,
  }) =>
      NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: decimals)
          .format(amount);

  /// Thousands-separated number (e.g. `1,234,567`).
  static String number(num value, {String? locale}) =>
      NumberFormat.decimalPattern(locale).format(value);

  /// Short magnitude form (e.g. `1.2K`, `3.4M`).
  static String compactNumber(num value, {String? locale}) =>
      NumberFormat.compact(locale: locale).format(value);
}
