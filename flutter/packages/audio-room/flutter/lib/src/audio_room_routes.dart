import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'data/audio_room_api_service.dart';
import 'data/audio_room_remote_datasource.dart';
import 'domain/audio_room_repository.dart';
import 'data/audio_room_repository_impl.dart';
import 'domain/room_model.dart';
import 'presentation/bloc/create_room/create_room_bloc.dart';
import 'presentation/bloc/room_list/room_list_bloc.dart';
import 'presentation/bloc/room_management/room_management_bloc.dart';
import 'presentation/view/create_room_page.dart';
import 'presentation/view/room_list_page.dart';
import 'presentation/view/room_settings_page.dart';
import 'presentation/widgets/overlay/audio_room_app_overlay.dart';

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
              final verifiedRoom = state.extra as RoomModel?;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AudioRoomAppOverlay.openRoom(roomId, verifiedRoom: verifiedRoom);
                if (context.mounted) context.pop();
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) {
                  final extra = state.extra;
                  RoomModel? room;
                  void Function(RoomModel)? onUpdated;
                  if (extra is Map<String, dynamic>) {
                    room = extra['room'] as RoomModel?;
                    onUpdated = extra['onUpdated'] as void Function(RoomModel)?;
                  } else if (extra is RoomModel) {
                    room = extra;
                  }
                  final roomId =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  final repository = _createRepository();
                  return BlocProvider(
                    create: (_) =>
                        RoomManagementBloc(repository: repository),
                    child: room != null
                        ? RoomSettingsPage(room: room, onUpdated: onUpdated)
                        : _RoomSettingsLoader(
                            roomId: roomId, repository: repository),
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

class _RoomSettingsLoader extends StatefulWidget {
  final int roomId;
  final AudioRoomRepository repository;

  const _RoomSettingsLoader({
    required this.roomId,
    required this.repository,
  });

  @override
  State<_RoomSettingsLoader> createState() => _RoomSettingsLoaderState();
}

class _RoomSettingsLoaderState extends State<_RoomSettingsLoader> {
  RoomModel? _room;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoom();
  }

  Future<void> _fetchRoom() async {
    final result = await widget.repository.getRoom(widget.roomId);
    if (!mounted) return;
    result.when(
      success: (response) {
        setState(() {
          _room = response.data;
          _loading = false;
        });
      },
      failure: (message, _) {
        setState(() {
          _error = message;
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Room not found')),
      );
    }

    return RoomSettingsPage(room: _room!);
  }
}
