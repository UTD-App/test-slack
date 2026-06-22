import 'dart:convert';

/// Resolves `binding` fields inside a Stac JSON template against a data item.
///
/// UTD Studio emits data-bound nodes like:
///   { "type": "text",  "binding": "name" }
///   { "type": "image", "binding": "image" }
///
/// Given a data item `{ "name": "أحمد", "image": "https://…" }`, this produces
/// plain Stac JSON the standard renderer understands:
///   { "type": "text",  "data": "أحمد" }
///   { "type": "image", "src": "https://…", "imageType": "network" }
///
/// Bindings may be relative (`name`) or fully-qualified (`chat.conversations.name`);
/// the last dot-segment is used as the lookup key against the item.
class StacBinding {
  const StacBinding._();

  /// Returns a deep copy of [template] with all `binding` nodes resolved
  /// against [item]. The original template is never mutated.
  static Map<String, dynamic> resolve(
    Map<String, dynamic> template,
    Map<String, dynamic> item,
  ) {
    final clone = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
    _walk(clone, item);
    return clone;
  }

  /// Stamps the row [item] onto every action node nested inside [node] — any
  /// map that carries an `actionType` (e.g. an inner like / comment button's
  /// `onTap`, a per-row overflow menu, a swipe action). This gives interactive
  /// elements *inside* a list row the same row context that a row-level
  /// `onItemTap` already gets, so the (package-owned) action can read the row's
  /// id via `model['item']`.
  ///
  /// Generic by design: it keys off `actionType` alone, so it is not tied to any
  /// package or action name. An action that already declares its own `item`
  /// (an explicit override in the template) is left untouched. The tree is
  /// mutated in place — call it on the clone returned by [resolve], never on a
  /// shared template.
  static void injectItemContext(dynamic node, Map<String, dynamic> item) {
    if (node is Map<String, dynamic>) {
      // Recurse into existing children first, then stamp this node, so we never
      // walk into the `item` payload we are about to attach.
      for (final value in node.values) {
        injectItemContext(value, item);
      }
      if (node['actionType'] is String && !node.containsKey('item')) {
        node['item'] = item;
      }
    } else if (node is List) {
      for (final child in node) {
        injectItemContext(child, item);
      }
    }
  }

  static void _walk(dynamic node, Map<String, dynamic> item) {
    if (node is Map<String, dynamic>) {
      final binding = node['binding'];
      if (binding is String && binding.isNotEmpty) {
        _applyBinding(node, binding, item);
      }
      // Conditional visibility: drop any child (inside a children list or a
      // single `child` slot) whose `visibleBinding` resolves to a falsy value
      // — e.g. an online dot when `online` is false, or an unread badge when
      // `unread_count` is 0. This keeps templates declarative without needing
      // an `if` widget.
      for (final value in node.values) {
        if (value is List) {
          value.removeWhere((c) => _isHidden(c, item));
        }
      }
      if (_isHidden(node['child'], item)) {
        node.remove('child');
      }
      for (final value in node.values) {
        _walk(value, item);
      }
    } else if (node is List) {
      node.removeWhere((c) => _isHidden(c, item));
      for (final child in node) {
        _walk(child, item);
      }
    }
  }

  /// Whether [n] declares a `visibleBinding` that resolves to a falsy value
  /// for [item] (and should therefore be removed before rendering).
  static bool _isHidden(dynamic n, Map<String, dynamic> item) {
    if (n is! Map) return false;
    final vb = n['visibleBinding'];
    if (vb is! String || vb.isEmpty) return false;
    return !_truthy(_lookup(vb, item));
  }

  static bool _truthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s.isNotEmpty && s != '0' && s != 'false' && s != 'null';
    }
    return true;
  }

  /// Stringifies a bound value for display. ISO-8601 datetimes (e.g. a chat
  /// row's `time`) are shortened to `HH:mm` for today, else `yyyy/MM/dd` — so
  /// the UI never shows a raw `2026-06-05T11:34:07+00:00` timestamp.
  static String? _display(dynamic value) {
    if (value == null) return null;
    if (value is String && value.contains('T')) {
      final dt = DateTime.tryParse(value);
      if (dt != null) {
        final l = dt.toLocal();
        final now = DateTime.now();
        final hh = l.hour.toString().padLeft(2, '0');
        final mm = l.minute.toString().padLeft(2, '0');
        if (l.year == now.year && l.month == now.month && l.day == now.day) {
          return '$hh:$mm';
        }
        final mo = l.month.toString().padLeft(2, '0');
        final dd = l.day.toString().padLeft(2, '0');
        return '${l.year}/$mo/$dd';
      }
    }
    return value.toString();
  }

  static void _applyBinding(
    Map<String, dynamic> node,
    String binding,
    Map<String, dynamic> item,
  ) {
    final value = _lookup(binding, item);
    final type = node['type'];

    switch (type) {
      case 'text':
        node['data'] = _display(value) ?? (node['data'] ?? '');
        break;
      case 'image':
        final url = value?.toString() ?? (node['src'] ?? '');
        if (url.isEmpty) {
          // An empty image binding. ONLY the AVATAR keeps a visible round person
          // placeholder so the "change photo" tap area stays usable when the user
          // has no picture. Every OTHER empty image (country flag, cover, …) must
          // VANISH — otherwise it paints a stray gray person circle where a
          // missing flag/cover should simply be absent. Leaving src empty lets the
          // image parser render SizedBox.shrink().
          final isAvatar = binding.toLowerCase().endsWith('avatar');
          if (isAvatar) {
            final w = node['width'];
            final h = node['height'];
            final num dim = (w is num) ? w : (h is num ? h : 96);
            node
              ..clear()
              ..['type'] = 'container'
              ..['alignment'] = 'center'
              ..['decoration'] = {
                'type': 'boxDecoration',
                'color': '#E2E8F0',
                'shape': 'circle',
              }
              ..['child'] = {
                'type': 'icon',
                'icon': 'person',
                'size': dim * 0.6,
                'color': '#94A3B8',
              };
            if (w != null) node['width'] = w;
            if (h != null) node['height'] = h;
          } else {
            node['src'] = '';
            node['imageType'] = 'network';
          }
        } else {
          node['src'] = url;
          node['imageType'] = 'network';
        }
        break;
      case 'textFormField':
      case 'utdTextField':
        // Pre-fill an editable field with the bound value (e.g. profile name).
        node['initialValue'] = value?.toString() ?? (node['initialValue'] ?? '');
        break;
      case 'icon':
        // Bound icon name (e.g. a tab's `icon` field) → the Material icon name.
        node['icon'] = value?.toString() ?? (node['icon'] ?? '');
        break;
      default:
        // Generic fallback: expose the value under `data` for custom widgets.
        if (value != null) node['data'] = value;
    }
  }

  static dynamic _lookup(String binding, Map<String, dynamic> item) {
    if (item.containsKey(binding)) return item[binding];
    final last = binding.split('.').last;
    return item[last];
  }
}
