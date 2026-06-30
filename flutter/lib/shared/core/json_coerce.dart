/// Tolerant JSON primitive coercion for model parsers on the launch/cache
/// hot-path, where a raw `as int` / `as num?` cast would throw (and crash the
/// app, when it runs outside a try/catch) if the server — or a Hive round-trip —
/// serialized a value as a different primitive type than expected.
library;

/// Coerces [value] to an int: accepts int, any num (double), or a numeric
/// String, falling back to 0 for null / unparseable input.
int coerceInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
