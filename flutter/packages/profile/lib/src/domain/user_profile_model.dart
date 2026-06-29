import 'user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    super.uuid,
    super.name,
    super.bio,
    super.avatar,
    super.covers,
    super.coverPaths,
    super.countryName,
    super.countryFlag,
    super.gender,
    super.birthday,
    super.onlineTime,
    super.isMe,
    super.extensions,
  });

  static const _knownKeys = {
    'id',
    'name',
    'bio',
    'country',
    'profile',
    'online_time',
    'is_me',
    'email',
    'phone',
    'uuid',
    'firebase_uuid',
    'notification_id',
    'is_first',
    'auth_token',
    'roles',
    'settings',
  };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final country = json['country'] as Map<String, dynamic>?;
    final profile = json['profile'] as Map<String, dynamic>?;

    final ext = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!_knownKeys.contains(entry.key)) {
        ext[entry.key] = entry.value;
      }
    }

    return UserProfileModel(
      id: (json['id'] as int?) ?? 0,
      uuid: json['uuid']?.toString(),
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      // Prefer the backend-built `image` URL (an absolute, correctly-bucketed
      // URL from the Media seam — e.g. GCS) and fall back to the raw `avatar`
      // path only when it's absent. resolveMediaUrl passes absolute http(s)
      // URLs through untouched; a raw path would instead be resolved against
      // domainUrl/storage (LOCAL Laravel disk), which 404s when media actually
      // lives on cloud storage — that was the "avatar uploads but never shows".
      avatar: (profile?['image'] ?? profile?['avatar']) as String?,
      // Prefer the backend-resolved `cover_images` (absolute, correctly-bucketed
      // URLs) and fall back to the raw `covers` paths — same rationale as avatar
      // above (a raw path would 404 when media lives on cloud storage).
      covers: _coerceStringList(profile?['cover_images'] ?? profile?['covers']),
      coverPaths: _coerceStringList(profile?['covers']),
      countryName: country?['name'] as String?,
      countryFlag: country?['flag'] as String?,
      gender: profile?['gender'] as int?,
      birthday: profile?['birthday']?.toString(),
      onlineTime: json['online_time'] as String?,
      isMe: (json['is_me'] as bool?) ?? false,
      extensions: ext,
    );
  }

  // ── Profile-page fields ───────────────────────────────────────
  // Read from the `extensions` map (any non-core JSON key). NO fabricated
  // fallbacks: a value shows only when the backend actually sends it. Package-
  // owned sections (received gifts, social stats, wallet…) are rendered by the
  // packages themselves via UiSlot.userProfile, not fabricated here.
  // Sender/receiver levels are contributed by the Gifts package under the
  // `gifts` section (Eagle convention: wealth = sender level, charm = receiver
  // level). Fall back to them so the identity level pills light up whenever
  // Gifts is installed, without the Profile package depending on Gifts code.
  int? get wealthLevel => _asInt('wealth_level') ?? _giftsLevel('sender_level');
  int? get charmLevel => _asInt('charm_level') ?? _giftsLevel('receiver_level');

  int? _giftsLevel(String key) {
    final gifts = extensions['gifts'];
    if (gifts is Map) {
      final v = gifts[key];
      if (v is num) return v.toInt();
    }
    return null;
  }

  // Decorative avatar frame URL — owned by the (not-yet-installed) frame
  // package. Null until that package sends it; never a hardcoded local asset,
  // so with no frame package the avatar renders on its own.
  String? get avatarFrame {
    final v = extensions['avatar_frame'] ?? extensions['frame'];
    final s = v?.toString();
    return (s != null && s.isNotEmpty) ? s : null;
  }

  /// Age computed from [birthday] (any parseable date). Null when absent or
  /// invalid, so the UI shows it only when the backend actually sends a birthday.
  int? get age {
    final b = birthday;
    if (b == null || b.isEmpty) return null;
    final dob = DateTime.tryParse(b);
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return (years >= 0 && years < 150) ? years : null;
  }

  // Guard with `is List` (like covers/socialStats) so a malformed non-list
  // `badges` value can't throw — falls back to an empty list.
  List<String> get badges => extensions['badges'] is List
      ? (extensions['badges'] as List).map((e) => e.toString()).toList()
      : const [];

  /// Friends / Following / Followers counts (denormalised on the backend user).
  /// Empty when the backend doesn't send them.
  Map<String, int> get socialStats {
    final s = extensions['stats'];
    if (s is Map) {
      return {
        'friends': (s['friends'] as num?)?.toInt() ?? 0,
        'following': (s['following'] as num?)?.toInt() ?? 0,
        'followers': (s['followers'] as num?)?.toInt() ?? 0,
      };
    }
    return const {};
  }

  /// Coerce a backend value (a List from JSON, or null) into a clean list of
  /// non-empty path/URL strings. Tolerant of nulls / non-string entries.
  static List<String> _coerceStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  int? _asInt(String key) {
    final v = extensions[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
