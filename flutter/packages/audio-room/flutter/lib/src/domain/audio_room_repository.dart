import 'dart:io';

import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import 'blacklist_entry_model.dart';
import 'room_admin_model.dart';
import 'room_category_model.dart';
import 'room_model.dart';
import 'room_visitor_model.dart';

abstract class AudioRoomRepository {
  Future<Result<BaseResponse<List<RoomModel>>>> getRooms({
    int page = 1,
    int? categoryId,
    String? search,
    String? sortBy,
  });

  Future<Result<BaseResponse<RoomModel>>> getRoom(int id);

  Future<Result<BaseResponse<RoomModel>>> createRoom({
    required String name,
    required int mode,
    String? intro,
    int? roomType,
    int? roomClass,
    String? password,
    File? cover,
    File? emptySeatIcon,
    File? lockedSeatIcon,
    String? emptySeatIconPreset,
    String? lockedSeatIconPreset,
  });

  Future<Result<BaseResponse<RoomModel>>> updateRoom(
    int id, {
    String? name,
    String? intro,
    String? rule,
    String? background,
    File? backgroundFile,
    String? password,
    int? mode,
    int? roomType,
    int? roomClass,
    bool? isCommentsClosed,
    bool? freeMic,
    File? cover,
    File? emptySeatIcon,
    File? lockedSeatIcon,
    String? emptySeatIconPreset,
    String? lockedSeatIconPreset,
    bool removeBackground = false,
  });

  Future<Result<BaseResponse>> deleteRoom(int id);

  Future<Result<BaseResponse<RoomModel>>> enterRoom(int id, {String? password});

  Future<Result<BaseResponse>> exitRoom(int id);

  Future<Result<BaseResponse<RoomModel?>>> getMyRoom();

  Future<Result<BaseResponse<List<RoomVisitorModel>>>> getRoomUsers(int id, {int page = 1});

  Future<Result<BaseResponse>> toggleFavorite(int id);

  Future<Result<BaseResponse>> toggleComments(int id, bool closed);

  Future<Result<BaseResponse>> changeMode(int id, int mode);

  Future<Result<BaseResponse<List<RoomCategoryModel>>>> getCategories();

  Future<Result<BaseResponse>> removePassword(int id);

  // Admin management
  Future<Result<BaseResponse<List<RoomAdminModel>>>> getAdmins(int roomId);

  Future<Result<BaseResponse>> addAdmin(int roomId, int userId);

  Future<Result<BaseResponse>> removeAdmin(int roomId, int userId);

  // Blacklist management
  Future<Result<BaseResponse<List<BlacklistEntryModel>>>> getBlacklist(int roomId);

  Future<Result<BaseResponse>> kickUser(int roomId, int userId, {int minutes = 5});

  Future<Result<BaseResponse>> banUser(int roomId, int userId, {int? durationSeconds, String? reason});

  Future<Result<BaseResponse>> unbanUser(int roomId, int userId);

  // Favorites
  Future<Result<BaseResponse<List<RoomModel>>>> getFavoriteRooms();

  // Room config
  Future<Result<BaseResponse<Map<String, dynamic>>>> getRoomConfig();

  // Moderation
  Future<Result<BaseResponse>> muteWriting(int roomId, int userId);

  Future<Result<BaseResponse>> unmuteWriting(int roomId, int userId);

  // Yellow banner
  Future<Result<BaseResponse>> sendBanner(int roomId, String message);

  // Pinned message
  Future<Result<BaseResponse>> pinMessage(int roomId, Map<String, dynamic> data);

  Future<Result<BaseResponse>> unpinMessage(int roomId);

  // Role check
  Future<Result<BaseResponse<Map<String, dynamic>>>> checkRole(int roomId);
}

abstract class AudioRoomRemoteDataSource {
  Future<Result<BaseResponse<List<RoomModel>>>> getRooms({int page, int? categoryId, String? search, String? sortBy});
  Future<Result<BaseResponse<RoomModel>>> getRoom(int id);
  Future<Result<BaseResponse<RoomModel>>> createRoom({required String name, required int mode, String? intro, int? roomType, int? roomClass, String? password, File? cover, File? emptySeatIcon, File? lockedSeatIcon, String? emptySeatIconPreset, String? lockedSeatIconPreset});
  Future<Result<BaseResponse<RoomModel>>> updateRoom(int id, {String? name, String? intro, String? rule, String? background, File? backgroundFile, String? password, int? mode, int? roomType, int? roomClass, bool? isCommentsClosed, bool? freeMic, File? cover, File? emptySeatIcon, File? lockedSeatIcon, String? emptySeatIconPreset, String? lockedSeatIconPreset, bool removeBackground = false});
  Future<Result<BaseResponse>> deleteRoom(int id);
  Future<Result<BaseResponse<RoomModel>>> enterRoom(int id, {String? password});
  Future<Result<BaseResponse>> exitRoom(int id);
  Future<Result<BaseResponse<RoomModel?>>> getMyRoom();
  Future<Result<BaseResponse<List<RoomVisitorModel>>>> getRoomUsers(int id, {int page});
  Future<Result<BaseResponse>> toggleFavorite(int id);
  Future<Result<BaseResponse>> toggleComments(int id, bool closed);
  Future<Result<BaseResponse>> changeMode(int id, int mode);
  Future<Result<BaseResponse<List<RoomCategoryModel>>>> getCategories();
  Future<Result<BaseResponse>> removePassword(int id);
  Future<Result<BaseResponse<List<RoomAdminModel>>>> getAdmins(int roomId);
  Future<Result<BaseResponse>> addAdmin(int roomId, int userId);
  Future<Result<BaseResponse>> removeAdmin(int roomId, int userId);
  Future<Result<BaseResponse<List<BlacklistEntryModel>>>> getBlacklist(int roomId);
  Future<Result<BaseResponse>> kickUser(int roomId, int userId, {int minutes});
  Future<Result<BaseResponse>> banUser(int roomId, int userId, {int? durationSeconds, String? reason});
  Future<Result<BaseResponse>> unbanUser(int roomId, int userId);
  Future<Result<BaseResponse<List<RoomModel>>>> getFavoriteRooms();
  Future<Result<BaseResponse<Map<String, dynamic>>>> getRoomConfig();
  Future<Result<BaseResponse>> muteWriting(int roomId, int userId);
  Future<Result<BaseResponse>> unmuteWriting(int roomId, int userId);
  Future<Result<BaseResponse>> sendBanner(int roomId, String message);
  Future<Result<BaseResponse>> pinMessage(int roomId, Map<String, dynamic> data);
  Future<Result<BaseResponse>> unpinMessage(int roomId);
  Future<Result<BaseResponse<Map<String, dynamic>>>> checkRole(int roomId);
}
