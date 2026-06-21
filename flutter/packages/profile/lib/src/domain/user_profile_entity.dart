import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final int id;

  /// Public, user-facing identifier (the short UID shown on the profile and used
  /// in search), distinct from the internal database [id]. May be null/empty for
  /// legacy records that predate UID generation.
  final String? uuid;
  final String? name;
  final String? bio;
  final String? avatar;

  /// Resolved, displayable URLs for the profile cover banner (0..3 images).
  /// Empty when the user has no covers. Use these for DISPLAY.
  final List<String> covers;

  /// Raw stored cover paths (the canonical values to send back to the backend
  /// when editing — avoids baking the emulator host into the saved value).
  /// Parallel to [covers] by index.
  final List<String> coverPaths;
  final String? countryName;
  final String? countryFlag;
  final int? gender;
  final String? birthday;
  final String? onlineTime;
  final bool isMe;
  final Map<String, dynamic> extensions;

  const UserProfileEntity({
    required this.id,
    this.uuid,
    this.name,
    this.bio,
    this.avatar,
    this.covers = const [],
    this.coverPaths = const [],
    this.countryName,
    this.countryFlag,
    this.gender,
    this.birthday,
    this.onlineTime,
    this.isMe = false,
    this.extensions = const {},
  });

  @override
  List<Object?> get props => [
        id,
        uuid,
        name,
        bio,
        avatar,
        covers,
        coverPaths,
        countryName,
        countryFlag,
        gender,
        birthday,
        onlineTime,
        isMe,
        extensions,
      ];
}
