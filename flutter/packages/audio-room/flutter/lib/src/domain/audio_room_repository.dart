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
}

class AudioRoomRepositoryImpl implements AudioRoomRepository {
  final AudioRoomRemoteDataSource remoteDataSource;

  AudioRoomRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<BaseResponse<List<RoomModel>>>> getRooms({
    int page = 1,
    int? categoryId,
    String? search,
    String? sortBy,
  }) =>
      remoteDataSource.getRooms(page: page, categoryId: categoryId, search: search, sortBy: sortBy);

  @override
  Future<Result<BaseResponse<RoomModel>>> getRoom(int id) =>
      remoteDataSource.getRoom(id);

  @override
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
  }) =>
      remoteDataSource.createRoom(
        name: name,
        mode: mode,
        intro: intro,
        roomType: roomType,
        roomClass: roomClass,
        password: password,
        cover: cover,
        emptySeatIcon: emptySeatIcon,
        lockedSeatIcon: lockedSeatIcon,
        emptySeatIconPreset: emptySeatIconPreset,
        lockedSeatIconPreset: lockedSeatIconPreset,
      );

  @override
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
  }) =>
      remoteDataSource.updateRoom(
        id,
        name: name,
        intro: intro,
        rule: rule,
        background: background,
        backgroundFile: backgroundFile,
        password: password,
        mode: mode,
        roomType: roomType,
        roomClass: roomClass,
        isCommentsClosed: isCommentsClosed,
        freeMic: freeMic,
        cover: cover,
        emptySeatIcon: emptySeatIcon,
        lockedSeatIcon: lockedSeatIcon,
        emptySeatIconPreset: emptySeatIconPreset,
        lockedSeatIconPreset: lockedSeatIconPreset,
      );

  @override
  Future<Result<BaseResponse>> deleteRoom(int id) =>
      remoteDataSource.deleteRoom(id);

  @override
  Future<Result<BaseResponse<RoomModel>>> enterRoom(int id, {String? password}) =>
      remoteDataSource.enterRoom(id, password: password);

  @override
  Future<Result<BaseResponse>> exitRoom(int id) =>
      remoteDataSource.exitRoom(id);

  @override
  Future<Result<BaseResponse<RoomModel?>>> getMyRoom() =>
      remoteDataSource.getMyRoom();

  @override
  Future<Result<BaseResponse<List<RoomVisitorModel>>>> getRoomUsers(int id, {int page = 1}) =>
      remoteDataSource.getRoomUsers(id, page: page);

  @override
  Future<Result<BaseResponse>> toggleFavorite(int id) =>
      remoteDataSource.toggleFavorite(id);

  @override
  Future<Result<BaseResponse>> toggleComments(int id, bool closed) =>
      remoteDataSource.toggleComments(id, closed);

  @override
  Future<Result<BaseResponse>> changeMode(int id, int mode) =>
      remoteDataSource.changeMode(id, mode);

  @override
  Future<Result<BaseResponse<List<RoomCategoryModel>>>> getCategories() =>
      remoteDataSource.getCategories();

  @override
  Future<Result<BaseResponse>> removePassword(int id) =>
      remoteDataSource.removePassword(id);

  @override
  Future<Result<BaseResponse<List<RoomAdminModel>>>> getAdmins(int roomId) =>
      remoteDataSource.getAdmins(roomId);

  @override
  Future<Result<BaseResponse>> addAdmin(int roomId, int userId) =>
      remoteDataSource.addAdmin(roomId, userId);

  @override
  Future<Result<BaseResponse>> removeAdmin(int roomId, int userId) =>
      remoteDataSource.removeAdmin(roomId, userId);

  @override
  Future<Result<BaseResponse<List<BlacklistEntryModel>>>> getBlacklist(int roomId) =>
      remoteDataSource.getBlacklist(roomId);

  @override
  Future<Result<BaseResponse>> kickUser(int roomId, int userId, {int minutes = 5}) =>
      remoteDataSource.kickUser(roomId, userId, minutes: minutes);

  @override
  Future<Result<BaseResponse>> banUser(int roomId, int userId, {int? durationSeconds, String? reason}) =>
      remoteDataSource.banUser(roomId, userId, durationSeconds: durationSeconds, reason: reason);

  @override
  Future<Result<BaseResponse>> unbanUser(int roomId, int userId) =>
      remoteDataSource.unbanUser(roomId, userId);

  @override
  Future<Result<BaseResponse<List<RoomModel>>>> getFavoriteRooms() =>
      remoteDataSource.getFavoriteRooms();

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> getRoomConfig() =>
      remoteDataSource.getRoomConfig();
}

abstract class AudioRoomRemoteDataSource {
  Future<Result<BaseResponse<List<RoomModel>>>> getRooms({int page, int? categoryId, String? search, String? sortBy});
  Future<Result<BaseResponse<RoomModel>>> getRoom(int id);
  Future<Result<BaseResponse<RoomModel>>> createRoom({required String name, required int mode, String? intro, int? roomType, int? roomClass, String? password, File? cover, File? emptySeatIcon, File? lockedSeatIcon, String? emptySeatIconPreset, String? lockedSeatIconPreset});
  Future<Result<BaseResponse<RoomModel>>> updateRoom(int id, {String? name, String? intro, String? rule, String? background, File? backgroundFile, String? password, int? mode, int? roomType, int? roomClass, bool? isCommentsClosed, bool? freeMic, File? cover, File? emptySeatIcon, File? lockedSeatIcon, String? emptySeatIconPreset, String? lockedSeatIconPreset});
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
}
