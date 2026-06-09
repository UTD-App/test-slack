import 'package:flutter/foundation.dart';

/// Targeted "force parsing" for server-driven Stac JSON.
///
/// The Stac engine throws (and the whole screen goes blank) when a field has
/// the wrong primitive type — e.g. `text.data` arrives as an `int`, or an
/// image `src` is `null`. Instead of crashing, we coerce the known
/// string-expected fields to `String` *before* `Stac.fromJson`, and log every
/// coercion so issues surface in the device logs (grep `[UTD][coerce]`).
///
/// Scope is intentionally TARGETED (not every field): only the keys that are
/// known to be string-typed in Stac and known to crash on mismatch. This keeps
/// real bugs visible in the logs instead of being silently "fixed" everywhere.
class StacCoerce {
  StacCoerce._();

  /// Keys whose value Stac expects to be a `String`. A non-string scalar here
  /// (int/double/bool) is coerced via `toString()`; `null` becomes `''`.
  static const Set<String> _stringKeys = {
    'data',        // text.data
    'src',         // image.src  (null here = parse crash)
    'hintText',
    'labelText',
    'routeName',
    'route',
    'fontFamily',
    'semanticLabel',
  };

  /// Coerce in place and return the same object (idempotent — safe to call on
  /// every rebuild). `path` is only used for logging.
  static dynamic sanitize(dynamic node, [String path = r'$']) {
    if (node is Map) {
      for (final key in node.keys.toList()) {
        final value = node[key];
        if (value is Map || value is List) {
          sanitize(value, '$path.$key');
        } else if (_stringKeys.contains(key) && value is! String) {
          if (value == null) {
            node[key] = '';
            _log('$path.$key', 'null');
          } else if (value is num || value is bool) {
            node[key] = value.toString();
            _log('$path.$key', value.runtimeType.toString());
          }
        }
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        final value = node[i];
        if (value is Map || value is List) sanitize(value, '$path[$i]');
      }
    }
    return node;
  }

  static void _log(String at, String wasType) {
    debugPrint('[UTD][coerce] $at was $wasType -> String (force-parsed)');
  }
}
