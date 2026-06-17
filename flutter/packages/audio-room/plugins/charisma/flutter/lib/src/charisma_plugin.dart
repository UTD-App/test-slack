import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'data/charisma_api_service.dart';
import 'data/charisma_remote_datasource.dart';
import 'domain/charisma_model.dart';
import 'domain/charisma_repository.dart';
import 'presentation/bloc/charisma_bloc.dart';
import 'presentation/view/charisma_leaderboard_sheet.dart';

class CharismaPlugin extends AudioRoomPlugin {
  late final CharismaBloc _bloc;
  bool _isActive = false;
  UTDRoomController? _controller;
  int? _currentRoomId;

  CharismaPlugin() {
    final repository = CharismaRepositoryImpl(
      remoteDataSource: CharismaRemoteDataSourceImpl(
        apiService: CharismaApiService(),
      ),
    );
    _bloc = CharismaBloc(repository: repository);
    _bloc.stream.listen((state) {
      if (state.statusState != RequestState.loading) {
        _isActive = state.charismaActive;
      }
    });
    _bloc.add(const FetchCharismaLevelsEvent());
  }

  @override
  String get id => 'charisma';

  @override
  String get displayName => 'Charisma';

  @override
  List<String> get conflictsWith => const ['pk', 'cinema'];

  @override
  List<String> get rtmMessageTypes => const [
        'updateCharisma',
        'startCharisma',
        'closeCharisma',
      ];

  @override
  void onControllerReady(UTDRoomController controller) {
    _controller = controller;
  }

  @override
  void onRoomEnter(int roomId, String userId) {
    _currentRoomId = roomId;
    _bloc.add(LoadRoomCharismaEvent(roomId: roomId));
  }

  @override
  void onRoomExit(int roomId, String userId) {
    _isActive = false;
    _currentRoomId = null;
    _controller = null;
    _bloc.add(const InitCharismaEvent());
  }

  @override
  void onRtmMessage(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'startCharisma':
        _isActive = true;
        final roomId = data['room_id'] as int?;
        if (roomId != null) {
          _bloc.add(LoadRoomCharismaEvent(roomId: roomId, activeOverride: true));
        }
      case 'closeCharisma':
        _isActive = false;
        _bloc.add(const InitCharismaEvent());
      case 'updateCharisma':
        final charismaList = data['charisma'] as List?;
        if (charismaList != null) {
          final models = charismaList
              .map((e) => CharismaModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _bloc.add(UpdateCharismaEvent(data: models));
        }
    }
  }

  @override
  Widget? buildControlsWidget(BuildContext context, int roomId) {
    return BlocBuilder<CharismaBloc, CharismaState>(
      bloc: _bloc,
      buildWhen: (prev, curr) => prev.charismaActive != curr.charismaActive,
      builder: (context, state) {
        if (!state.charismaActive) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
          onPressed: () =>
              CharismaLeaderboardSheet.show(context, _bloc, _controller),
        );
      },
    );
  }

  @override
  Widget? buildOverlayWidget(BuildContext context, int roomId) => null;

  @override
  Widget? buildSeatBadge(BuildContext context, String userId, int roomId) {
    return BlocBuilder<CharismaBloc, CharismaState>(
      bloc: _bloc,
      buildWhen: (prev, curr) =>
          prev.charismaActive != curr.charismaActive || prev.data != curr.data,
      builder: (context, state) {
        if (!state.charismaActive) return const SizedBox.shrink();

        final userData = state.data?.cast<CharismaModel?>().firstWhere(
              (e) => e!.userId.toString() == userId,
              orElse: () => null,
            );
        final total = userData?.total ?? '0';

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.pinkAccent, size: 10),
                const SizedBox(width: 2),
                Text(
                  total,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  List<PluginSettingRow> getSettingRows(BuildContext context, int roomId) {
    return [
      PluginSettingRow(
        title: 'الكاريزما',
        type: PluginSettingType.toggle,
        currentValue: _isActive,
        onToggle: (value) {
          _isActive = value;
          _bloc.add(ChangeCharismaStatusEvent(roomId: roomId, status: value));
          final type = value ? 'startCharisma' : 'closeCharisma';
          _controller?.sendRoomMessage({
            'type': type,
            'data': {'room_id': roomId},
          });
        },
      ),
      if (_isActive)
        PluginSettingRow(
          title: 'ريست الكاريزما',
          type: PluginSettingType.action,
          onTap: () {
            _bloc.add(ResetCharismaEvent(roomId: roomId));
            final resetData = _bloc.state.data
                    ?.map((e) => {
                          'user_id': e.userId,
                          'total': '0',
                          'position': 0,
                        })
                    .toList() ??
                [];
            _controller?.sendRoomMessage({
              'type': 'updateCharisma',
              'data': {'charisma': resetData},
            });
          },
        ),
    ];
  }

  CharismaBloc get bloc => _bloc;
}
