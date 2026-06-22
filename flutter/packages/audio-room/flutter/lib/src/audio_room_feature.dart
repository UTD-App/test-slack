import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/addons/app_feature.dart';
import 'package:utd_app/addons/ui_contribution.dart';
import 'package:utd_app/addons/ui_slot.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'audio_room_mode_plugin.dart';
import 'audio_room_plugin.dart';
import 'audio_room_routes.dart';
import 'audio_room_strings.dart';
import 'data/audio_room_api_service.dart';
import 'data/audio_room_remote_datasource.dart';
import 'domain/audio_room_repository.dart';
import 'domain/room_model.dart';
import 'presentation/bloc/room_list_bloc.dart';
import 'presentation/view/room_list_page.dart';

class AudioRoomFeature extends AppFeature {
  static AudioRoomFeature? _instance;
  static AudioRoomFeature? get instance => _instance;
  static List<AudioRoomPlugin> get registeredPlugins =>
      _instance?._plugins ?? const [];

  final List<AudioRoomPlugin> _plugins = [];
  final List<AudioRoomModePlugin> _modePlugins = [];

  UTDRoomController? activeController;
  RoomModel? activeRoom;
  int? activeRoomId;
  final ValueNotifier<Set<String>> commentBannedUsers = ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>?> pinnedMessage = ValueNotifier(null);

  void setActiveRoom(UTDRoomController controller, RoomModel room, int roomId) {
    activeController = controller;
    activeRoom = room;
    activeRoomId = roomId;
  }

  void clearActiveRoom() {
    activeController = null;
    activeRoom = null;
    activeRoomId = null;
    commentBannedUsers.value = {};
    pinnedMessage.value = null;
  }

  AudioRoomFeature() {
    _instance = this;
  }

  @override
  String get id => 'com.utd.audio_room';

  @override
  String get displayName => 'Audio Room';

  @override
  String get version => '1.0.0';

  @override
  String? get packageSlug => 'audio-room';

  @override
  List<String> get dependencies => const [];

  @override
  List<GoRoute> getRoutes() => AudioRoomRoutes.routes();

  @override
  List<UiContribution> getUiContributions() => [
        UiContribution(
          slot: UiSlot.bottomNav,
          label: 'Rooms',
          order: 20,
          activeIcon: const Icon(Icons.mic, color: Colors.blue),
          inactiveIcon: const Icon(Icons.mic_none),
          builder: (context) => BlocProvider(
            create: (_) => RoomListBloc(
              repository: AudioRoomRepositoryImpl(
                remoteDataSource: AudioRoomRemoteDataSourceImpl(
                  apiService: AudioRoomApiService(),
                ),
              ),
            ),
            child: const RoomListPage(),
          ),
        ),
      ];

  @override
  Map<String, Map<String, String>> getTranslations() => audioRoomTranslations;

  void registerPlugin(AudioRoomPlugin plugin) {
    _plugins.add(plugin);
  }

  List<AudioRoomPlugin> get plugins => List.unmodifiable(_plugins);

  void registerModePlugin(AudioRoomModePlugin mode) {
    _modePlugins.add(mode);
  }

  List<AudioRoomModePlugin> get modePlugins =>
      List.unmodifiable(_modePlugins);
}
