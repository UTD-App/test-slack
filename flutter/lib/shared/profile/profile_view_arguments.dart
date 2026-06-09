/// Host-app seam for a user-profile view, shared by the Profile package (which
/// provides it into the widget tree) and any package that contributes a section
/// to [UiSlot.userProfile] (Gifts, Moments…). The Flutter analog of the backend
/// `App\Contracts\ProfileContributor`: contributed sections read their own slice
/// of the already-loaded profile payload without re-fetching.
///
/// The Profile package exposes a `ProfileViewArguments` via `Provider` while a
/// profile page is on screen. Contributors `context.read<ProfileViewArguments>()`
/// inside a try/catch — when no profile scope is present (or the Profile package
/// isn't installed) they simply render nothing.
class ProfileViewArguments {
  /// The aggregated profile payload, keyed by contributor section
  /// (e.g. `'gifts' => {'count': 12, 'items': [...]}`).
  final Map<String, dynamic> sections;

  /// The id of the user whose profile is being viewed.
  final int userId;

  /// Whether the viewer is looking at their own profile.
  final bool isMe;

  const ProfileViewArguments({
    this.sections = const {},
    this.userId = 0,
    this.isMe = false,
  });

  /// This contributor's slice of the payload, or an empty map when absent.
  Map<String, dynamic> section(String key) {
    final value = sections[key];
    return value is Map ? value.cast<String, dynamic>() : const {};
  }
}
