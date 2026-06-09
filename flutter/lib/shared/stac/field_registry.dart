import 'package:flutter/widgets.dart';

/// Generic, package-agnostic registry mapping a field **id** → its
/// [TextEditingController].
///
/// This is the base-level mechanism that lets any widget expose its live text to
/// other widgets by a shared `id` — without coupling the Base or the Studio to
/// any specific package (chat, forum, comments, …). A `utdTextField` (emitted by
/// a basic UTD-Studio TextField in "Live" mode) creates/owns its controller
/// under an `id`, and any other widget placed separately and designed freely in
/// the Studio (e.g. `chat.sendButton`) looks up the SAME controller by that `id`
/// to:
///   • react to typing (toggle/enable/disable),
///   • read the text on demand, then clear the field.
///
/// Controllers are created lazily and shared (whoever asks first creates it), so
/// registration order between the field and its readers doesn't matter. They are
/// disposed when the owning field unmounts via [release].
class FieldRegistry {
  FieldRegistry._();

  static final Map<String, TextEditingController> _controllers = {};

  /// The controller for [id], creating it on first use. Shared by the field and
  /// any widget bound to the same id.
  static TextEditingController of(String id) =>
      _controllers.putIfAbsent(id, () => TextEditingController());

  /// Whether a controller for [id] currently exists.
  static bool has(String id) => _controllers.containsKey(id);

  /// Drops [id]'s controller (called by the owning field on dispose). Any reader
  /// holds the same instance, so this only runs when the field itself leaves.
  static void release(String id) {
    _controllers.remove(id)?.dispose();
  }
}
