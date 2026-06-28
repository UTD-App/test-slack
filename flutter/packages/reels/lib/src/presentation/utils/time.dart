/// Facebook-style relative time ("5 minutes ago" / "منذ 5 دقائق").
///
/// Parses a backend ISO-8601 string (e.g. `2026-06-08T13:33:41.000000Z`) and
/// returns a localized "time ago" label. Falls back to the raw input when it
/// can't be parsed. Pass [arabic] = true for Arabic phrasing.
String timeAgo(String iso, {bool arabic = false}) {
  if (iso.isEmpty) return '';

  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;

  final diff = DateTime.now().difference(dt.toLocal());
  final secs = diff.inSeconds;

  if (arabic) {
    if (secs < 60) return 'الآن';
    final mins = diff.inMinutes;
    if (mins < 60) return 'منذ ${_ar(mins, 'دقيقة', 'دقيقتين', 'دقائق')}';
    final hours = diff.inHours;
    if (hours < 24) return 'منذ ${_ar(hours, 'ساعة', 'ساعتين', 'ساعات')}';
    final days = diff.inDays;
    if (days < 7) return 'منذ ${_ar(days, 'يوم', 'يومين', 'أيام')}';
    if (days < 30) return 'منذ ${_ar((days / 7).floor(), 'أسبوع', 'أسبوعين', 'أسابيع')}';
    if (days < 365) return 'منذ ${_ar((days / 30).floor(), 'شهر', 'شهرين', 'أشهر')}';
    return 'منذ ${_ar((days / 365).floor(), 'سنة', 'سنتين', 'سنوات')}';
  }

  if (secs < 60) return 'just now';
  final mins = diff.inMinutes;
  if (mins < 60) return '$mins ${_en(mins, 'minute')} ago';
  final hours = diff.inHours;
  if (hours < 24) return '$hours ${_en(hours, 'hour')} ago';
  final days = diff.inDays;
  if (days < 7) return '$days ${_en(days, 'day')} ago';
  if (days < 30) {
    final w = (days / 7).floor();
    return '$w ${_en(w, 'week')} ago';
  }
  if (days < 365) {
    final mo = (days / 30).floor();
    return '$mo ${_en(mo, 'month')} ago';
  }
  final y = (days / 365).floor();
  return '$y ${_en(y, 'year')} ago';
}

/// Arabic count phrasing: 1 → singular, 2 → dual, 3–10 → "n plural",
/// 11+ → "n singular" (the standard Arabic pluralization for these units).
String _ar(int n, String one, String two, String few) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n >= 3 && n <= 10) return '$n $few';
  return '$n $one';
}

String _en(int n, String unit) => n == 1 ? unit : '${unit}s';
