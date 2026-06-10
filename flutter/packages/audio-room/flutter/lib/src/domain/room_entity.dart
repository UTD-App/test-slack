import 'package:equatable/equatable.dart';

class RoomEntity extends Equatable {
  final int id;
  final int numId;
  final int ownerId;
  final String roomName;
  final String? roomCover;
  final String? roomIntro;
  final String? roomRule;
  final String? roomBackground;
  final bool hasPassword;
  final int mode;
  final int roomStatus;
  final bool isAfk;
  final int visitorCount;
  final List<String> visitorImages;
  final int? roomTypeId;
  final int? roomClassId;
  final String? categoryName;
  final bool isCommentsClosed;
  final bool freeMic;
  final int maxAdmin;
  final String? ownerName;
  final String? ownerAvatar;
  final String? ownerCountryFlag;
  final DateTime? createdAt;

  const RoomEntity({
    required this.id,
    required this.numId,
    required this.ownerId,
    required this.roomName,
    this.roomCover,
    this.roomIntro,
    this.roomRule,
    this.roomBackground,
    this.hasPassword = false,
    this.mode = 9,
    this.roomStatus = 1,
    this.isAfk = false,
    this.visitorCount = 0,
    this.visitorImages = const [],
    this.roomTypeId,
    this.roomClassId,
    this.categoryName,
    this.isCommentsClosed = false,
    this.freeMic = false,
    this.maxAdmin = 4,
    this.ownerName,
    this.ownerAvatar,
    this.ownerCountryFlag,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
