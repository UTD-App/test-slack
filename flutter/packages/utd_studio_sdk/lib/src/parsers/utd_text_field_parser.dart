import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;
// ignore: implementation_imports — reuse the vendored name→IconData map (same fork).
import 'package:stac/src/utils/icon_utils.dart';

import '../core/field_registry.dart';

/// Model for a generic, **referenceable** text field (UTD extension):
/// ```json
/// {
///   "type": "utdTextField",
///   "id": "message",
///   "label": "الاسم",          // optional — rendered as a floating label
///   "hint": "اكتب رسالة…",      // optional placeholder
///   "obscureText": true,         // optional (passwords) → auto eye toggle
///   "keyboardType": "emailAddress" | "number" | "phone",
///   "fillColor": "#1affffff",   // optional (translucent → white text auto-picked)
///   "radius": 24,                 // optional border radius
///   "textColor": "#ffffff",     // optional — else auto from fillColor luminance/alpha
///   "hintColor": "#80ffffff",   // optional placeholder colour
///   "cursorColor": "#ffffff",   // optional
///   "borderColor": "#33ffffff", // optional border side colour (needs radius)
///   "prefixIcon": "alternate_email", // optional leading Material icon name
///   "prefixIconColor": "#d9a0ff"     // optional leading-icon colour
/// }
/// ```
///
/// Emitted by a basic UTD-Studio `TextField` whose **"Live (referenceable)"**
/// toggle is on. Unlike core `textFormField` (which hides its controller inside
/// itself), this field shares its [TextEditingController] via [FieldRegistry]
/// under [id], so any other widget can read/observe it by the same id. It also
/// mirrors its value into the enclosing `form` ([StacFormScope]) — so form
/// actions (e.g. `core.login`) keep reading it exactly like a `textFormField`.
///
/// FROSTED-FIELD SUPPORT: `textColor`/`prefixIcon`/`borderColor`/`*Color` are
/// optional extras for the auth screens' frosted look. They are robust to the
/// Studio Craft→Stac transform DROPPING them: the text colour is auto-derived
/// from the fill (translucent/dark fill → white text) so the field stays legible
/// on a dark surface even when only `fillColor` survives, and the password eye
/// toggle keys off `obscureText` (which always survives) — never a regression.
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
    this.textColor,
    this.hintColor,
    this.cursorColor,
    this.borderColor,
    this.prefixIcon,
    this.prefixIconColor,
  });

  final String id;
  final String? label;
  final String? hint;
  final String? initialValue;
  final bool obscureText;
  final String? keyboardType;
  final String? fillColor;
  final double? radius;
  final String? textColor;
  final String? hintColor;
  final String? cursorColor;
  final String? borderColor;
  final String? prefixIcon;
  final String? prefixIconColor;

  factory StacUtdTextField.fromJson(Map<String, dynamic> json) {
    final r = json['radius'];
    String? str(String k) => (json[k] as String?)?.trim().isEmpty ?? true
        ? null
        : (json[k] as String).trim();
    return StacUtdTextField(
      id: (json['id'] ?? 'field').toString(),
      label: str('label'),
      hint: str('hint'),
      initialValue: json['initialValue'] as String?,
      obscureText: json['obscureText'] == true,
      keyboardType: json['keyboardType'] as String?,
      fillColor: json['fillColor'] as String?,
      radius: r is num ? r.toDouble() : null,
      textColor: str('textColor'),
      hintColor: str('hintColor'),
      cursorColor: str('cursorColor'),
      borderColor: str('borderColor'),
      prefixIcon: str('prefixIcon'),
      prefixIconColor: str('prefixIconColor'),
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
  // acquire (not of): reference-counts ownership so the shared controller is
  // disposed only when the LAST field using this id unmounts (the same id can be
  // mounted on Login + a pushed Register/Forgot at once).
  late final TextEditingController _controller =
      FieldRegistry.acquire(widget.model.id);

  /// Live obscure state for the password eye toggle (seeded from the model).
  late bool _obscure = widget.model.obscureText;

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
  /// sits inside a `form`. Uses `getInheritedWidgetOfExactType` (NOT `dependOn…`):
  /// it looks the scope up WITHOUT registering a dependency, so it's legal to call
  /// from `initState` (where `dependOn…` throws once a `form` is actually present)
  /// and avoids needless rebuilds — we only need to write into the scope's map.
  /// A form-less placement (e.g. a chat composer) stays silent.
  void _writeForm(String value) {
    final scope = context.getInheritedWidgetOfExactType<StacFormScope>();
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

  /// The effective text colour: explicit `textColor`, else auto-derived from the
  /// fill — a translucent (low-alpha) or dark fill implies a dark surface behind
  /// it → white text; an opaque light fill → dark text. This keeps frosted auth
  /// fields legible even when the Studio transform drops the `textColor` prop.
  Color? _resolveTextColor() {
    final explicit = _hex(widget.model.textColor);
    if (explicit != null) return explicit;
    final fill = _hex(widget.model.fillColor);
    if (fill == null) return null; // no fill → keep the theme default
    final translucent = fill.a < 0.5;
    if (translucent || fill.computeLuminance() < 0.5) return Colors.white;
    return const Color(0xFF241B45); // dark text on a light/opaque fill
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final colors = Theme.of(context).colorScheme;
    final radius = m.radius;
    final textColor = _resolveTextColor();
    final borderColor = _hex(m.borderColor);
    final border = radius == null && borderColor == null
        ? null
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius ?? 0),
            borderSide: borderColor == null
                ? BorderSide.none
                : BorderSide(color: borderColor, width: 1.2),
          );
    final hintColor = _hex(m.hintColor) ?? textColor?.withValues(alpha: 0.55);

    // Leading icon (e.g. @ / lock) — resolved from the Material name map.
    final prefixData =
        m.prefixIcon == null ? null : materialIconMap[m.prefixIcon];
    final prefixColor = _hex(m.prefixIconColor) ??
        textColor?.withValues(alpha: 0.8) ??
        colors.primary;

    // Password eye toggle — keyed off obscureText (which always survives the
    // transform), so the eye works regardless of the extra frosted props.
    final Widget? suffix = m.obscureText
        ? IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              size: 20,
              color: textColor?.withValues(alpha: 0.7),
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          )
        : null;

    return TextField(
      controller: _controller,
      onChanged: _writeForm,
      obscureText: _obscure,
      keyboardType: _keyboard,
      minLines: 1,
      maxLines: _obscure ? 1 : 5,
      style: textColor == null ? null : TextStyle(color: textColor),
      cursorColor: _hex(m.cursorColor) ?? textColor,
      decoration: InputDecoration(
        labelText: m.label,
        labelStyle: textColor == null ? null : TextStyle(color: hintColor),
        hintText: m.hint,
        hintStyle: hintColor == null ? null : TextStyle(color: hintColor),
        filled: m.fillColor != null,
        fillColor: _hex(m.fillColor) ?? colors.surfaceContainerHighest,
        prefixIcon: prefixData == null
            ? null
            : Icon(prefixData, size: 20, color: prefixColor),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
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
