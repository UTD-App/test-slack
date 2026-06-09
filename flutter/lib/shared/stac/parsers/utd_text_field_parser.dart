import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

import '../field_registry.dart';

/// Model for a generic, **referenceable** text field (UTD extension):
/// ```json
/// {
///   "type": "utdTextField",
///   "id": "message",
///   "label": "الاسم",          // optional — rendered as a floating label
///   "hint": "اكتب رسالة…",      // optional placeholder
///   "obscureText": true,         // optional (passwords)
///   "keyboardType": "emailAddress" | "number" | "phone",
///   "fillColor": "#ffffff",     // optional
///   "radius": 24                  // optional border radius
/// }
/// ```
///
/// Emitted by a basic UTD-Studio `TextField` whose **"Live (referenceable)"**
/// toggle is on. Unlike core `textFormField` (which hides its controller inside
/// itself), this field shares its [TextEditingController] via [FieldRegistry]
/// under [id], so any other widget can read/observe it by the same id. It also
/// mirrors its value into the enclosing `form` ([StacFormScope]) — so form
/// actions (e.g. `core.login`) keep reading it exactly like a `textFormField`.
class StacUtdTextField {
  const StacUtdTextField({
    required this.id,
    this.label,
    this.hint,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType,
    this.fillColor,
    this.radius,
  });

  final String id;
  final String? label;
  final String? hint;
  final String? initialValue;
  final bool obscureText;
  final String? keyboardType;
  final String? fillColor;
  final double? radius;

  factory StacUtdTextField.fromJson(Map<String, dynamic> json) {
    final r = json['radius'];
    return StacUtdTextField(
      id: (json['id'] ?? 'field').toString(),
      label: (json['label'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['label'] as String?,
      hint: (json['hint'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['hint'] as String?,
      initialValue: json['initialValue'] as String?,
      obscureText: json['obscureText'] == true,
      keyboardType: json['keyboardType'] as String?,
      fillColor: json['fillColor'] as String?,
      radius: r is num ? r.toDouble() : null,
    );
  }
}

class StacUtdTextFieldParser extends StacParser<StacUtdTextField> {
  const StacUtdTextFieldParser();

  @override
  String get type => 'utdTextField';

  @override
  StacUtdTextField getModel(Map<String, dynamic> json) =>
      StacUtdTextField.fromJson(json);

  @override
  Widget parse(BuildContext context, StacUtdTextField model) =>
      _UtdTextField(model);
}

class _UtdTextField extends StatefulWidget {
  const _UtdTextField(this.model);

  final StacUtdTextField model;

  @override
  State<_UtdTextField> createState() => _UtdTextFieldState();
}

class _UtdTextFieldState extends State<_UtdTextField> {
  late final TextEditingController _controller =
      FieldRegistry.of(widget.model.id);

  @override
  void initState() {
    super.initState();
    // Seed the shared controller from an initialValue only if it's still empty
    // (don't clobber text a peer widget may already share).
    final init = widget.model.initialValue;
    if (init != null && init.isNotEmpty && _controller.text.isEmpty) {
      _controller.text = init;
    }
    // Mirror the current value into the enclosing form (if any) so form actions
    // can read it — same contract as core `textFormField`.
    _writeForm(_controller.text);
  }

  /// Writes [value] into the enclosing [StacFormScope.formData] when this field
  /// sits inside a `form`. Read directly (not via `StacFormScope.of`) so a
  /// form-less placement (e.g. a chat composer) stays silent instead of logging.
  void _writeForm(String value) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<StacFormScope>();
    if (scope != null) scope.formData[widget.model.id] = value;
  }

  @override
  void dispose() {
    FieldRegistry.release(widget.model.id);
    super.dispose();
  }

  TextInputType? get _keyboard {
    switch (widget.model.keyboardType) {
      case 'emailAddress':
        return TextInputType.emailAddress;
      case 'number':
        return TextInputType.number;
      case 'phone':
        return TextInputType.phone;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final colors = Theme.of(context).colorScheme;
    final radius = m.radius;
    final border = radius == null
        ? null
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          );
    return TextField(
      controller: _controller,
      onChanged: _writeForm,
      obscureText: m.obscureText,
      keyboardType: _keyboard,
      minLines: 1,
      maxLines: m.obscureText ? 1 : 5,
      decoration: InputDecoration(
        labelText: m.label,
        hintText: m.hint,
        filled: m.fillColor != null,
        fillColor: _hex(m.fillColor) ?? colors.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: border,
      ),
    );
  }
}

/// Parses a `#RRGGBB`/`#AARRGGBB` hex from UTD Studio; null when empty/invalid.
Color? _hex(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  var h = s.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}
