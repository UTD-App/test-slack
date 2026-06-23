import 'package:flutter/widgets.dart';

import '../interfaces/interfaces.dart';
import '../runtime/studio_runtime.dart';

/// Localises a server-driven screen's translatable `Text` nodes BEFORE render.
///
/// A `Text` node is localised when it carries either:
///   • `"tKey": "auth.login"`            — an explicit translation key, or
///   • `"binding": "t.auth.login"`       — a binding whose root source is `t`.
///
/// Its `data` is set to the current-locale string via the app-provided
/// [StudioRuntime.translate] port (e.g. `context.tr(key)`), and the translation
/// `binding` is stripped so the later data-binding pass (Scope/utdObject) doesn't
/// try to resolve `t.*` against a data object and blank it out.
///
/// No-op (returns [json] unchanged) when no translate port is wired. Returns a
/// fresh structure on the touched branches — the source JSON is never mutated.
Map<String, dynamic> localizeStac(Map<String, dynamic> json, BuildContext context) {
  final translate = StudioRuntime.instance.translate;
  if (translate == null) return json;
  final out = _walk(json, context, translate);
  return out is Map<String, dynamic> ? out : json;
}

dynamic _walk(dynamic node, BuildContext ctx, StacTranslate translate) {
  if (node is Map) {
    final out = <String, dynamic>{};
    node.forEach((k, v) => out[k.toString()] = _walk(v, ctx, translate));

    if (out['type'] == 'text') {
      final key = _translationKey(out['tKey'], out['binding']);
      if (key != null) {
        final value = translate(ctx, key);
        // Override only on a REAL hit. App i18n returns the key itself when a
        // string is missing — in that case keep the node's literal `data` as the
        // fallback instead of showing the raw key.
        if (value.isNotEmpty && value != key) out['data'] = value;
        // It's a translation, not a data binding — don't let the Scope pass touch it.
        out.remove('binding');
      }
    }
    return out;
  }
  if (node is List) {
    return node.map((e) => _walk(e, ctx, translate)).toList();
  }
  return node;
}

/// The translation key from an explicit `tKey` or a `t.<key>` binding, else null.
String? _translationKey(dynamic tKey, dynamic binding) {
  if (tKey is String && tKey.isNotEmpty) return tKey;
  if (binding is String && binding.startsWith('t.') && binding.length > 2) {
    return binding.substring(2);
  }
  return null;
}
