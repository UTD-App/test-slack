import 'dart:io';

import 'package:dio/dio.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/base_response.dart';

import '../domain/audio_room_repository.dart';
import '../domain/room_admin_model.dart';
import '../domain/room_category_model.dart';
import '../domain/room_model.dart';
import '../domain/room_visitor_model.dart';
import 'audio_room_api_service.dart';

class AudioRoomRemoteDataSourceImpl implements AudioRoomRemoteDataSource {
  final AudioRoomApiService apiService;

  AudioRoomRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Result<BaseResponse<List<RoomModel>>>> getRooms({
    int page = 1,
    int? categoryId,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (categoryId != null) params['category_id'] = categoryId;
    if (search != null && search.isNotEmpty) params['search'] = search;

    return apiService.get(
      apiService.roomsPath(),
      queryParameters: params,
      fromJson: (json) => BaseResponse<List<RoomModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<RoomModel>>> getRoom(int id) async {
    return apiService.get(
      apiService.roomPath(id),
      fromJson: (json) => BaseResponse<RoomModel>.fromJson(
        json,
        fromJsonT: (data) => RoomModel.fromJson(data as Map<String, dynamic>),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<RoomModel>>> createRoom({
    required String name,
    required int mode,
    String? intro,
    int? roomType,
    int? roomClass,
    String? password,
    File? cover,
  }) async {
    final formMap = <String, dynamic>{
      'room_name': name,
      'mode': mode,
    };
    if (intro != null) formMap['room_intro'] = intro;
    if (roomType != null) formMap['room_type'] = roomType;
    if (roomClass != null) formMap['room_class'] = roomClass;
    if (password != null) formMap['room_pass'] = password;
    if (cover != null) {
      formMap['room_cover'] = await MultipartFile.fromFile(cover.path);
    }

    return apiService.post(
      apiService.roomsPath(),
      data: FormData.fromMap(formMap),
      fromJson: (json) => BaseResponse<RoomModel>.fromJson(
        json,
        fromJsonT: (data) => RoomModel.fromJson(data as Map<String, dynamic>),
      ),
    );
  }

  @override
  Future<Result<BaseResponse<RoomModel>>> updateRoom(
    int id, {
    String? name,
    String? intro,
    String? rule,
    String? background,
    String? password,
    int? mode,
    int? roomType,
    int? roomClass,
    bool? isCommentsClosed,
    bool? freeMic,
    File? cover,
  }) async {
    final formMap = <String, dynamic>{};
    if (name != null) formMap['room_name'] = name;
    if (intro != null) formMap['room_intro'] = intro;
    if (rule != null) formMap['room_rule'] = rule;
    if (background != null) formMap['room_background'] = background;
    if (password != null) formMap['room_pass'] = password;
    if (mode != null) formMap['mode'] = mode;
    if (roomType != null) formMap['room_type'] = roomType;
    if (roomClass != null) formMap['room_class'] = roomClass;
    if (isCommentsClosed != null) formMap['is_comment_closed'] = isCommentsClosed ? 1 : 0;
    if (freeMic != null) formMap['free_mic'] = freeMic ? 1 : 0;
    if (cover != null) {
      formMap['room_cover'] = await MultipartFile.fromFile(cover.path);
    }

    return apiService.post(
      apiService.roomPath(id),
      data: FormData.fromMap({...formMap, '_method': 'PUT'}),
      fromJson: (json) => BaseResponse<RoomModel>.fromJson(
        json,
        fromJsonT: (data) => RoomModel.fromJson(data as Map<String, dynamic>),
      ),
    );
  }

  @override
  Future<Result<BaseResponse>> deleteRoom(int id) async {
    return apiService.delete(
      apiService.roomPath(id),
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse<RoomModel>>> enterRoom(int id, {String? password}) async {
    final data = <String, dynamic>{};
    if (password != null) data['room_pass'] = password;

    return apiService.post(
      apiService.enterPath(id),
      data: data.isNotEmpty ? data : null,
      fromJson: (json) => BaseResponse<RoomModel>.fromJson(
        json,
        fromJsonT: (data) => RoomModel.fromJson(data as Map<String, dynamic>),
      ),
    );
  }

  @override
  Future<Result<BaseResponse>> exitRoom(int id) async {
    return apiService.post(
      apiService.exitPath(id),
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse<RoomModel?>>> getMyRoom() async {
    return apiService.get(
      apiService.myRoomPath(),
      fromJson: (json) => BaseResponse<RoomModel?>.fromJson(
        json,
        fromJsonT: (data) =>
            data != null ? RoomModel.fromJson(data as Map<String, dynamic>) : null,
      ),
    );
  }

  @override
  Future<Result<BaseResponse<List<RoomVisitorModel>>>> getRoomUsers(
    int id, {
    int page = 1,
  }) async {
    return apiService.get(
      apiService.usersPath(id),
      queryParameters: {'page': page},
      fromJson: (json) => BaseResponse<List<RoomVisitorModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => RoomVisitorModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse>> toggleFavorite(int id) async {
    return apiService.post(
      apiService.favoritePath(id),
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse>> toggleComments(int id, bool closed) async {
    return apiService.post(
      apiService.commentStatusPath(id),
      data: {'is_comment_closed': closed},
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse>> changeMode(int id, int mode) async {
    return apiService.post(
      apiService.modePath(id),
      data: {'mode': mode},
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse<List<RoomCategoryModel>>>> getCategories() async {
    return apiService.get(
      apiService.categoriesPath(),
      fromJson: (json) => BaseResponse<List<RoomCategoryModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => RoomCategoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse>> removePassword(int id) async {
    return apiService.post(
      apiService.removePasswordPath(id),
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  // Admin management

  @override
  Future<Result<BaseResponse<List<RoomAdminModel>>>> getAdmins(int roomId) async {
    return apiService.get(
      apiService.adminsPath(roomId),
      fromJson: (json) => BaseResponse<List<RoomAdminModel>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => RoomAdminModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse>> addAdmin(int roomId, int userId) async {
    return apiService.post(
      apiService.adminsPath(roomId),
      data: {'user_id': userId},
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse>> removeAdmin(int roomId, int userId) async {
    return apiService.delete(
      apiService.adminPath(roomId, userId),
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  // Blacklist management

  @override
  Future<Result<BaseResponse<List<Map<String, dynamic>>>>> getBlacklist(int roomId) async {
    return apiService.get(
      apiService.blacklistPath(roomId),
      fromJson: (json) => BaseResponse<List<Map<String, dynamic>>>.fromJson(
        json,
        fromJsonT: (data) => (data as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      ),
    );
  }

  @override
  Future<Result<BaseResponse>> kickUser(
    int roomId,
    int userId, {
    int minutes = 5,
  }) async {
    return apiService.post(
      apiService.kickPath(roomId),
      data: {'user_id': userId, 'minutes': minutes},
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse>> banUser(
    int roomId,
    int userId, {
    int? durationSeconds,
    String? reason,
  }) async {
    final data = <String, dynamic>{'user_id': userId};
    if (durationSeconds != null) data['duration_seconds'] = durationSeconds;
    if (reason != null) data['reason'] = reason;

    return apiService.post(
      apiService.banPath(roomId),
      data: data,
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  @override
  Future<Result<BaseResponse>> unbanUser(int roomId, int userId) async {
    return apiService.delete(
      apiService.unbanPath(roomId, userId),
      fromJson: (json) => BaseResponse.fromJson(json),
    );
  }

  // Room config

  @override
  Future<Result<BaseResponse<Map<String, dynamic>>>> getRoomConfig() async {
    return apiService.get(
      apiService.roomConfigPath(),
      fromJson: (json) => BaseResponse<Map<String, dynamic>>.fromJson(
        json,
        fromJsonT: (data) => data as Map<String, dynamic>,
      ),
    );
  }
}
