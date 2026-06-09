/// Facebook-style relative time formatting for moment timestamps.
///
/// Parses a backend ISO-8601 string (e.g. `2026-06-08T13:33:41.000000Z`) and
/// returns a compact, language-neutral label: `now`, `5m`, `3h`, `2d`, `1w`,
/// `4mo`, `1y`. Falls back to the raw input when it can't be parsed.
String timeAgo(String iso) {
  if (iso.isEmpty) return '';

  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;

  final diff = DateTime.now().difference(dt.toLocal());
  final secs = diff.inSeconds;

  if (secs < 0) return 'now'; // clock skew / future timestamp
  if (secs < 60) return 'now';

  final mins = diff.inMinutes;
  if (mins < 60) return '${mins}m';

  final hours = diff.inHours;
  if (hours < 24) return '${hours}h';

  final days = diff.inDays;
  if (days < 7) return '${days}d';

  if (days < 30) return '${(days / 7).floor()}w';
  if (days < 365) return '${(days / 30).floor()}mo';
  return '${(days / 365).floor()}y';
}
