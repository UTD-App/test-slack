/// Shared input validators used across the whole app.
///
/// Two layers:
/// - **predicates** (`isEmail`, `isPhone`…) — pure `bool` checks for ad-hoc use.
/// - **field validators** (`emailField`, `requiredField`…) — return a
///   `String? Function(String?)` matching `TextInputWidget.validator`, so a
///   feature wires them straight into a form. Messages are passed in (already
///   localized by the caller) with English fallbacks.
///
/// ```dart
/// TextInputWidget(
///   validator: Validators.emailField(context.tr('auth.invalid_email')),
/// );
/// ```
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _phone = RegExp(r'^\+?[0-9]{7,15}$');

  // ── Predicates ────────────────────────────────────────────────
  static bool isNotEmpty(String? value) => value != null && value.trim().isNotEmpty;

  static bool isEmail(String value) => _email.hasMatch(value.trim());

  /// Accepts an optional leading `+` and 7–15 digits; ignores spaces, dashes
  /// and parentheses.
  static bool isPhone(String value) =>
      _phone.hasMatch(value.replaceAll(RegExp(r'[\s()-]'), ''));

  static bool isUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasScheme &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }

  /// At least [minLength] chars, containing both a letter and a digit.
  static bool isStrongPassword(String value, {int minLength = 8}) =>
      value.length >= minLength &&
      RegExp(r'[A-Za-z]').hasMatch(value) &&
      RegExp(r'[0-9]').hasMatch(value);

  // ── Field validators (for TextInputWidget.validator) ──────────
  static String? Function(String?) requiredField([
    String message = 'This field is required',
  ]) =>
      (value) => isNotEmpty(value) ? null : message;

  static String? Function(String?) emailField([
    String message = 'Enter a valid email',
  ]) =>
      (value) => isNotEmpty(value) && isEmail(value!) ? null : message;

  static String? Function(String?) phoneField([
    String message = 'Enter a valid phone number',
  ]) =>
      (value) => isNotEmpty(value) && isPhone(value!) ? null : message;

  static String? Function(String?) passwordField({
    int minLength = 8,
    String message = 'Password must be at least 8 chars with letters & numbers',
  }) =>
      (value) =>
          isNotEmpty(value) && isStrongPassword(value!, minLength: minLength)
              ? null
              : message;

  static String? Function(String?) minLengthField(
    int min, [
    String? message,
  ]) =>
      (value) => (value != null && value.trim().length >= min)
          ? null
          : (message ?? 'Must be at least $min characters');
}
