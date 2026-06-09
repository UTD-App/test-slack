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
          // لسه مفيش صورة (مستخدم بدون avatar): نرسم placeholder دائري بدل
          // Image.network('') اللي بتنهار وتنكمش لحجم صفر — فتختفي الصورة
          // وتبقى مش قابلة للنقر (يبان وكأن مفيش binding ولا action). الحجم
          // يفضل من width/height عشان منطقة النقر (تغيير الصورة) تفضل موجودة.
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
          node['src'] = url;
          node['imageType'] = 'network';
        }
        break;
      case 'textFormField':
      case 'utdTextField':
        // Pre-fill an editable field with the bound value (e.g. profile name).
        node['initialValue'] = value?.toString() ?? (node['initialValue'] ?? '');
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
