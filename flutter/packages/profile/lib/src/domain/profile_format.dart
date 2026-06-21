/// Formats a count the way social apps do: 1000 → "1K", 10500 → "10.5K",
/// 2_000_000 → "2M". Values under 1000 are shown as-is.
String formatCount(num value) {
  if (value < 1000) return value.toInt().toString();
  if (value < 1000000) {
    final k = value / 1000;
    return '${_trim(k)}K';
  }
  final m = value / 1000000;
  return '${_trim(m)}M';
}

String _trim(double v) {
  // Drop the decimal when it's a round number (1.0K → 1K).
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}
