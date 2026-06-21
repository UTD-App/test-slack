/// A single user row returned by `GET /users/search`.
///
/// Compact, viewer-safe shape (no email/phone) — just enough to render a search
/// result cell (avatar + name + UID) and open the user's profile on tap.
class SearchUser {
  final int id;
  final String name;
  final String uuid;
  final String? image;
  final bool isOnline;

  const SearchUser({
    required this.id,
    required this.name,
    required this.uuid,
    this.image,
    this.isOnline = false,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : '—',
      uuid: '${json['uuid'] ?? ''}',
      image: (json['image'] as String?)?.isNotEmpty == true
          ? json['image'] as String
          : null,
      isOnline: json['is_online'] == true,
    );
  }
}
