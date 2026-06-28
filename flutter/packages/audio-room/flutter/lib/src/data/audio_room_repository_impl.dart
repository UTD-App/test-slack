import 'dart:io';

import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../domain/audio_room_repository.dart';
import '../domain/blacklist_entry_model.dart';
import '../domain/room_admin_model.dart';
import '../domain/room_category_model.dart';
import '../domain/room_model.dart';
import '../domain/room_visitor_model.dart';

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
    bool removeBackground = false,
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
        removeBackground: removeBackground,
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

  @override
  Future<Result<BaseResponse>> muteWriting(int roomId, int userId) =>
      remoteDataSource.muteWriting(roomId, userId);

  @override
  Future<Result<BaseResponse>> unmuteWriting(int roomId, int userId) =>
      remoteDataSource.unmuteWriting(roomId, userId);

  @override
  Future<Result<BaseResponse>> sendBanner(int roomId, String message) =>
      remoteDataSource.sendBanner(roomId, message);

  @override
  Future<Result<BaseResponse>> pinMessage(int roomId, Map<String, dynamic> data) =>
      remoteDataSource.pinMessage(roomId, data);

  @override
  Future<Result<BaseResponse>> unpinMessage(int roomId) =>
      remoteDataSource.unpinMessage(roomId);

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> checkRole(int roomId) =>
      remoteDataSource.checkRole(roomId);
}
