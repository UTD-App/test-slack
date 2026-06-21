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
/// registration order between the field and its readers doesn't matter.
///
/// **Ownership is reference-counted:** the SAME `id` can legitimately be mounted
/// by more than one field at once (e.g. an `email` field reused on the Login,
/// Register and Forgot-password screens — Login stays mounted underneath a pushed
/// Register/Forgot). Each owning field [acquire]s on mount and [release]s on
/// unmount; the controller is disposed only when the LAST owner leaves. Without
/// this, unmounting one screen would dispose a controller another still holds →
/// "A TextEditingController was used after being disposed."
class FieldRegistry {
  FieldRegistry._();

  static final Map<String, TextEditingController> _controllers = {};

  /// How many owning fields currently hold each id (readers don't count).
  static final Map<String, int> _owners = {};

  /// The controller for [id], creating it on first use. Shared by the field and
  /// any widget bound to the same id. Does NOT change ownership — use [acquire]
  /// from an owning field so the controller's lifetime is tracked.
  static TextEditingController of(String id) =>
      _controllers.putIfAbsent(id, () => TextEditingController());

  /// Claims ownership of [id]'s controller (called by an owning field on mount),
  /// creating it on first use. Balance every call with [release].
  static TextEditingController acquire(String id) {
    _owners[id] = (_owners[id] ?? 0) + 1;
    return of(id);
  }

  /// Whether a controller for [id] currently exists.
  static bool has(String id) => _controllers.containsKey(id);

  /// Drops one owner of [id] (called by an owning field on dispose). The
  /// controller is disposed only when the last owner releases it, so a peer field
  /// sharing the same id keeps working.
  static void release(String id) {
    final remaining = (_owners[id] ?? 1) - 1;
    if (remaining <= 0) {
      _owners.remove(id);
      _controllers.remove(id)?.dispose();
    } else {
      _owners[id] = remaining;
    }
  }
}
