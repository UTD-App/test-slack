import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'data/audio_room_api_service.dart';
import 'data/audio_room_remote_datasource.dart';
import 'domain/audio_room_repository.dart';
import 'domain/room_model.dart';
import 'presentation/bloc/create_room_bloc.dart';
import 'presentation/bloc/room_list_bloc.dart';
import 'presentation/bloc/room_management_bloc.dart';
import 'presentation/view/audio_room_page.dart';
import 'presentation/view/create_room_page.dart';
import 'presentation/view/room_list_page.dart';
import 'presentation/view/room_settings_page.dart';

class AudioRoomRoutes {
  static const String rooms = '/rooms';
  static const String create = '/rooms/create';
  static const String room = '/rooms/:id';
  static const String settings = '/rooms/:id/settings';

  static String get roomsPath => '/rooms';
  static String get createPath => '/rooms/create';
  static String roomPath(int roomId) => '/rooms/$roomId';
  static String settingsPath(int roomId) => '/rooms/$roomId/settings';

  static AudioRoomRepository _createRepository() => AudioRoomRepositoryImpl(
        remoteDataSource: AudioRoomRemoteDataSourceImpl(
          apiService: AudioRoomApiService(),
        ),
      );

  static List<GoRoute> routes() {
    return [
      GoRoute(
        path: rooms,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => RoomListBloc(repository: _createRepository()),
            child: const RoomListPage(),
          );
        },
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) {
              return BlocProvider(
                create: (_) =>
                    CreateRoomBloc(repository: _createRepository()),
                child: const CreateRoomPage(),
              );
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final roomId =
                  int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final repository = _createRepository();
              return MultiBlocProvider(
                providers: [
                  RepositoryProvider<AudioRoomRepository>.value(
                    value: repository,
                  ),
                  BlocProvider(
                    create: (_) =>
                        RoomManagementBloc(repository: repository),
                  ),
                ],
                child: AudioRoomPage(roomId: roomId),
              );
            },
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) {
                  final room = state.extra as RoomModel?;
                  if (room == null) {
                    return const SizedBox.shrink();
                  }
                  return BlocProvider(
                    create: (_) =>
                        RoomManagementBloc(repository: _createRepository()),
                    child: RoomSettingsPage(room: room),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
