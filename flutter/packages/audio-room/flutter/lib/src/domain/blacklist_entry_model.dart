/// A single entry in a room's blacklist (banned user).
///
/// The backend (`RoomAdminController::blacklist`) returns the banned *user's*
/// id under the `id` key (not the ban-row id), alongside denormalized profile
/// fields, so [userId] reads from `id` and falls back to `user_id`.
class BlacklistEntryModel {
  final int userId;
  final String userName;
  final String? avatar;
  final String? countryFlag;
  final String? reason;
  final DateTime? bannedAt;
  final DateTime? expiresAt;
  final int? remainingSeconds;

  const BlacklistEntryModel({
    required this.userId,
    required this.userName,
    this.avatar,
    this.countryFlag,
    this.reason,
    this.bannedAt,
    this.expiresAt,
    this.remainingSeconds,
  });

  factory BlacklistEntryModel.fromJson(Map<String, dynamic> json) {
    return BlacklistEntryModel(
      userId: (json['id'] as num?)?.toInt() ??
          (json['user_id'] as num?)?.toInt() ??
          0,
      userName: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      countryFlag: json['country_flag'] as String?,
      reason: json['reason'] as String?,
      bannedAt: json['banned_at'] != null
          ? DateTime.tryParse(json['banned_at'].toString())
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      remainingSeconds: (json['remaining_seconds'] as num?)?.toInt(),
    );
  }
}
