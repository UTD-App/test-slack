/// Compact a number for counters, e.g. 500 → "500", 3000 → "3K",
/// 22500 → "22.5K", 1_500_000 → "1.5M". Trailing ".0" is dropped.
String compactNumber(num value) {
  if (value < 1000) return value.toInt().toString();
  if (value < 1000000) return '${_trim(value / 1000)}K';
  return '${_trim(value / 1000000)}M';
}

String _trim(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}
