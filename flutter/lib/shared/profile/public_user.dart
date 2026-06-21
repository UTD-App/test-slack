/// A single user's public, viewer-safe profile data as returned by
/// `GET /api/users/{id}` (the base endpoint that's always available, even when
/// the rich Profile package isn't installed).
///
/// Deliberately a small, flat shape — just the essentials the base
/// [VisitedProfileFallback] renders (avatar, name, gender, ID, bio, online,
/// social counters). The Profile package has its own richer model.
class PublicUser {
  final int id;
  final String name;
  final String uuid;
  final String? bio;

  /// Avatar URL. Prefers the backend-resolved absolute `image` (Media seam, e.g.
  /// GCS), falling back to the raw `avatar` path — resolve with `avatarUrl`.
  final String? avatar;

  /// 1 = male, 2 = female, null/other = unspecified (mirrors the Profile pkg).
  final int? gender;

  final String? countryName;
  final String? countryFlag;
  final bool isOnline;

  final int friends;
  final int following;
  final int followers;

  /// True when this is the signed-in user's own profile.
  final bool isMe;

  const PublicUser({
    required this.id,
    required this.name,
    required this.uuid,
    this.bio,
    this.avatar,
    this.gender,
    this.countryName,
    this.countryFlag,
    this.isOnline = false,
    this.friends = 0,
    this.following = 0,
    this.followers = 0,
    this.isMe = false,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    final profile = (json['profile'] is Map)
        ? (json['profile'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final country = (json['country'] is Map)
        ? (json['country'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final stats = (json['stats'] is Map)
        ? (json['stats'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return PublicUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : '—',
      uuid: '${json['uuid'] ?? ''}',
      bio: (json['bio'] as String?)?.trim().isNotEmpty == true
          ? (json['bio'] as String).trim()
          : null,
      avatar: (profile['image'] ?? profile['avatar']) as String?,
      gender: (profile['gender'] as num?)?.toInt(),
      countryName: country['name'] as String?,
      countryFlag: country['flag'] as String?,
      isOnline: json['is_online'] == true,
      friends: (stats['friends'] as num?)?.toInt() ?? 0,
      following: (stats['following'] as num?)?.toInt() ?? 0,
      followers: (stats['followers'] as num?)?.toInt() ?? 0,
      isMe: (json['is_me'] as bool?) ?? false,
    );
  }
}
