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
      id: (json['id'] as num?)?.toInt() ?? 0,
      numId: (json['num_id'] as num?)?.toInt() ?? 0,
      ownerId: (json['owner_id'] as num?)?.toInt() ?? 0,
      roomName: json['room_name'] as String? ?? '',
      roomCover: json['room_cover'] as String?,
      roomIntro: json['room_intro'] as String?,
      roomRule: json['room_rule'] as String?,
      roomBackground: json['room_background'] as String?,
      hasPassword: json['has_password'] as bool? ?? false,
      mode: (json['mode'] as num?)?.toInt() ?? 9,
      roomStatus: (json['room_status'] as num?)?.toInt() ?? 1,
      isAfk: json['is_afk'] as bool? ?? false,
      visitorCount: (json['visitor_count'] as num?)?.toInt() ?? 0,
      visitorImages: visitorImages,
      roomTypeId: (json['room_type'] as num?)?.toInt(),
      roomClassId: (json['room_class'] as num?)?.toInt(),
      categoryName: json['category_name'] as String?,
      isCommentsClosed: json['is_comment_closed'] as bool? ?? false,
      freeMic: json['free_mic'] as bool? ?? false,
      maxAdmin: (json['max_admin'] as num?)?.toInt() ?? 4,
      ownerName: json['owner_name'] as String?,
      ownerAvatar: json['owner_avatar'] as String?,
      ownerCountryFlag: json['owner_country_flag'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isOwner: json['is_owner'] as bool?,
      isAdmin: json['is_admin'] as bool?,
      streamConfig: json['stream_config'] as Map<String, dynamic>?,
    );
  }

  RoomModel copyWith({
    int? visitorCount,
    bool? isCommentsClosed,
    int? mode,
  }) {
    return RoomModel(
      id: id,
      numId: numId,
      ownerId: ownerId,
      roomName: roomName,
      roomCover: roomCover,
      roomIntro: roomIntro,
      roomRule: roomRule,
      roomBackground: roomBackground,
      hasPassword: hasPassword,
      mode: mode ?? this.mode,
      roomStatus: roomStatus,
      isAfk: isAfk,
      visitorCount: visitorCount ?? this.visitorCount,
      visitorImages: visitorImages,
      roomTypeId: roomTypeId,
      roomClassId: roomClassId,
      categoryName: categoryName,
      isCommentsClosed: isCommentsClosed ?? this.isCommentsClosed,
      freeMic: freeMic,
      maxAdmin: maxAdmin,
      ownerName: ownerName,
      ownerAvatar: ownerAvatar,
      ownerCountryFlag: ownerCountryFlag,
      createdAt: createdAt,
      isOwner: isOwner,
      isAdmin: isAdmin,
      streamConfig: streamConfig,
    );
  }
}
