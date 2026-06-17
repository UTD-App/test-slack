import 'room_entity.dart';

class RoomModel extends RoomEntity {
  final bool? isOwner;
  final bool? isAdmin;
  final Map<String, dynamic>? streamConfig;

  const RoomModel({
    required super.id,
    required super.numId,
    required super.ownerId,
    required super.roomName,
    super.roomCover,
    super.roomIntro,
    super.roomRule,
    super.roomBackground,
    super.hasPassword,
    super.mode,
    super.roomStatus,
    super.isAfk,
    super.visitorCount,
    super.visitorImages,
    super.roomTypeId,
    super.roomClassId,
    super.categoryName,
    super.isCommentsClosed,
    super.freeMic,
    super.maxAdmin,
    super.ownerName,
    super.ownerAvatar,
    super.ownerCountryFlag,
    super.createdAt,
    this.isOwner,
    this.isAdmin,
    this.streamConfig,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final visitorImages = (json['visitor_images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return RoomModel(
      id: _toInt(json['id']) ?? 0,
      numId: _toInt(json['num_id']) ?? 0,
      ownerId: _toInt(json['owner_id']) ?? 0,
      roomName: json['room_name']?.toString() ?? '',
      roomCover: json['room_cover']?.toString(),
      roomIntro: json['room_intro']?.toString(),
      roomRule: json['room_rule']?.toString(),
      roomBackground: json['room_background']?.toString(),
      hasPassword: _toBool(json['has_password']) ?? false,
      mode: _toInt(json['mode']) ?? 9,
      roomStatus: _toInt(json['room_status']) ?? 1,
      isAfk: _toBool(json['is_afk']) ?? false,
      visitorCount: _toInt(json['visitor_count']) ?? 0,
      visitorImages: visitorImages,
      roomTypeId: _toInt(json['room_type']),
      roomClassId: _toInt(json['room_class']),
      categoryName: json['category_name']?.toString(),
      isCommentsClosed: _toBool(json['is_comment_closed']) ?? false,
      freeMic: _toBool(json['free_mic']) ?? false,
      maxAdmin: _toInt(json['max_admin']) ?? 4,
      ownerName: json['owner_name']?.toString(),
      ownerAvatar: json['owner_avatar']?.toString(),
      ownerCountryFlag: json['owner_country_flag']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isOwner: _toBool(json['is_owner']),
      isAdmin: _toBool(json['is_admin']),
      streamConfig: json['stream_config'] as Map<String, dynamic>?,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return null;
  }

  RoomModel copyWith({
    String? roomName,
    String? roomCover,
    String? roomIntro,
    String? roomRule,
    String? roomBackground,
    bool? hasPassword,
    int? mode,
    int? visitorCount,
    bool? isCommentsClosed,
    bool? freeMic,
    String? ownerAvatar,
    bool? isAdmin,
  }) {
    return RoomModel(
      id: id,
      numId: numId,
      ownerId: ownerId,
      roomName: roomName ?? this.roomName,
      roomCover: roomCover ?? this.roomCover,
      roomIntro: roomIntro ?? this.roomIntro,
      roomRule: roomRule ?? this.roomRule,
      roomBackground: roomBackground ?? this.roomBackground,
      hasPassword: hasPassword ?? this.hasPassword,
      mode: mode ?? this.mode,
      roomStatus: roomStatus,
      isAfk: isAfk,
      visitorCount: visitorCount ?? this.visitorCount,
      visitorImages: visitorImages,
      roomTypeId: roomTypeId,
      roomClassId: roomClassId,
      categoryName: categoryName,
      isCommentsClosed: isCommentsClosed ?? this.isCommentsClosed,
      freeMic: freeMic ?? this.freeMic,
      maxAdmin: maxAdmin,
      ownerName: ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      ownerCountryFlag: ownerCountryFlag,
      createdAt: createdAt,
      isOwner: isOwner,
      isAdmin: isAdmin ?? this.isAdmin,
      streamConfig: streamConfig,
    );
  }
}
