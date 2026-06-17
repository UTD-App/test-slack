import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/app_config.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../audio_room_feature.dart';
import '../../data/pending_exit_manager.dart';
import '../../data/pip_manager.dart';
import '../../domain/audio_room_repository.dart';
import '../widgets/audio_room_app_overlay.dart';
import '../../domain/room_model.dart';
import '../bloc/room_management_bloc.dart';
import '../widgets/room/empty_seat_widget.dart';
import '../widgets/room/locked_seat_widget.dart';
import '../widgets/room/room_background_widget.dart';
import 'room_settings_page.dart';
import '../widgets/room/room_controls_bar.dart';
import '../widgets/room/room_header_widget.dart';
import '../widgets/room/room_messages_widget.dart';
import '../widgets/room/room_strings.dart';
import '../widgets/room/seat_avatar_widget.dart';
import '../widgets/room/seat_options_sheet.dart';
import '../widgets/room/speaker_invitation_dialog.dart';
import '../widgets/room_admin_sheet.dart';

class AudioRoomPage extends StatefulWidget {
  final int roomId;
  final RoomModel? verifiedRoom;
  final GoRouter? router;

  const AudioRoomPage({
    super.key,
    required this.roomId,
    this.verifiedRoom,
    this.router,
  });

  @override
  State<AudioRoomPage> createState() => _AudioRoomPageState();
}

class _AudioRoomPageState extends State<AudioRoomPage> {
  RoomModel? _room;
  bool _isLoading = true;
  String? _error;
  UTDRoomController? _controller;
  StreamSubscription? _joinSub;
  StreamSubscription? _leaveSub;
  StreamSubscription? _dataSub;
  StreamSubscription? _roleSub;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _flushPendingExits();

    final feature = AudioRoomFeature.instance;
    if (feature != null &&
        feature.activeRoomId == widget.roomId &&
        feature.activeController != null &&
        feature.activeController!.isConnected) {
      _controller = feature.activeController;
      _room = feature.activeRoom;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UTDMiniOverlayMachine.instance.changeState(
          UTDMiniOverlayState.inAudioRoom,
        );
        if (mounted && _controller != null) {
          _listenParticipantEvents(_controller!);
          _listenPluginMessages(_controller!);
        }
      });
    } else {
      _enterRoom();
    }
  }

  @override
  void dispose() {
    _joinSub?.cancel();
    _leaveSub?.cancel();
    _dataSub?.cancel();
    if (!UTDMiniOverlayMachine.instance.isMinimizing) {
      _roleSub?.cancel();
    }
    super.dispose();
  }

  Future<void> _enterRoom() async {
    if (widget.verifiedRoom != null) {
      setState(() {
        _room = widget.verifiedRoom;
        _isLoading = false;
      });
      _notifyPluginsEnter(widget.verifiedRoom!);
      return;
    }

    final repository = context.read<AudioRoomRepository>();
    final result = await repository.enterRoom(widget.roomId);

    switch (result) {
      case Success(data: final data):
        if (data.data != null) {
          setState(() {
            _room = data.data;
            _isLoading = false;
          });
          _notifyPluginsEnter(data.data!);
        } else {
          setState(() {
            _error = data.message;
            _isLoading = false;
          });
        }
      case Failure(message: final message):
        setState(() {
          _error = message;
          _isLoading = false;
        });
    }
  }

  void _notifyPluginsEnter(RoomModel room) {
    final userId = CacheManager.getUserData()?['id']?.toString() ?? '';
    for (final plugin in AudioRoomFeature.registeredPlugins) {
      plugin.onRoomEnter(room.id, userId);
    }
  }

  void _notifyPluginsExit() {
    if (_room == null) return;
    final userId = CacheManager.getUserData()?['id']?.toString() ?? '';
    for (final plugin in AudioRoomFeature.registeredPlugins) {
      plugin.onRoomExit(_room!.id, userId);
    }
  }

  void _minimizeRoom() {
    if (_controller == null || !_controller!.isConnected) return;
    UTDMiniOverlayMachine.instance.changeState(UTDMiniOverlayState.minimizing);
  }

  Future<void> _exitRoom() async {
    if (_isExiting) return;
    _isExiting = true;
    _notifyPluginsExit();
    PipManager.instance.disableAutoPip();
    UTDMiniOverlayMachine.instance.changeState(UTDMiniOverlayState.idle);
    AudioRoomFeature.instance?.clearActiveRoom();
    if (_controller != null) {
      final userId = CacheManager.getUserData()?['id']?.toString() ?? '';
      final seatIndex = _controller!.seatController.getSeatIndexByUserId(
        userId,
      );
      if (seatIndex >= 0) {
        await _controller!.seatController.leaveSeat(userId);
      }
      await _controller!.leave();
    }
    if (!mounted) return;
    final repository = context.read<AudioRoomRepository>();
    final result = await repository.exitRoom(widget.roomId);
    if (result is Failure) {
      await PendingExitManager.add(widget.roomId);
    }
    AudioRoomAppOverlay.closeRoom();
  }

  void _listenPluginMessages(UTDRoomController controller) {
    _dataSub = controller.dataStream.listen((data) {
      final type = data['type'] as String?;
      if (type == null) return;

      if (type == 'roleChange') {
        _handleRoleChangeRtm(data['data'] as Map<String, dynamic>? ?? data);
        return;
      }

      if (type == 'roomSettingsUpdate') {
        _handleRoomSettingsUpdateRtm(
          data['data'] as Map<String, dynamic>? ?? data,
        );
        return;
      }

      for (final plugin in AudioRoomFeature.registeredPlugins) {
        if (plugin.rtmMessageTypes.contains(type)) {
          plugin.onRtmMessage(
            type,
            data['data'] as Map<String, dynamic>? ?? data,
          );
        }
      }
    });
  }

  void _handleRoleChangeRtm(Map<String, dynamic> data) {
    if (!mounted) return;
    final targetUserId = data['user_id']?.toString();
    final role = data['role']?.toString();
    final userName = data['user_name']?.toString() ?? '';
    final promoterName = data['promoter_name']?.toString() ?? '';
    if (targetUserId == null || role == null || _controller == null) return;

    final localUserId = CacheManager.getUserData()?['id']?.toString() ?? '';
    final s = RoomStrings.of(context);
    final isPromotion = role == 'admin';

    final chatText = isPromotion
        ? s.userPromotedToAdmin(userName, promoterName)
        : s.userDemotedFromAdmin(userName, promoterName);
    _controller!.chatController.addDisplayMessage(
      UTDChatMessage(
        senderUserId: 'system',
        senderName: '',
        text: chatText,
        timestamp: DateTime.now(),
      ),
    );

    if (targetUserId == localUserId) {
      setState(() {
        _room = _room?.copyWith(isAdmin: isPromotion);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPromotion ? s.youAreNowAdmin : s.youAreNoLongerAdmin),
        ),
      );
    }
  }

  void _listenParticipantEvents(UTDRoomController controller) {
    final s = RoomStrings.of(context);
    _joinSub = controller.roomManager.participantJoinedStream.listen((p) {
      final name = p.name.isNotEmpty ? p.name : p.identity;
      controller.chatController.addDisplayMessage(
        UTDChatMessage(
          senderUserId: 'system',
          senderName: '',
          text: s.userJoined(name),
          timestamp: DateTime.now(),
        ),
      );
    });
    _leaveSub = controller.roomManager.participantLeftStream.listen((p) {
      final name = p.name.isNotEmpty ? p.name : p.identity;
      controller.chatController.addDisplayMessage(
        UTDChatMessage(
          senderUserId: 'system',
          senderName: '',
          text: s.userLeft(name),
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _flushPendingExits() async {
    final pendingIds = await PendingExitManager.getAll();
    if (pendingIds.isEmpty) return;
    final repository = context.read<AudioRoomRepository>();
    for (final id in pendingIds) {
      final result = await repository.exitRoom(id);
      if (result is Success) {
        await PendingExitManager.remove(id);
      }
    }
  }

  void _openSettings(RoomModel room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => RoomManagementBloc(
            repository: RepositoryProvider.of<AudioRoomRepository>(context),
          ),
          child: RoomSettingsPage(
            room: room,
            onUpdated: (RoomModel updated) {
              if (mounted) {
                setState(() {
                  _room = _room!.copyWith(
                    roomName: updated.roomName,
                    roomCover: updated.roomCover,
                    roomIntro: updated.roomIntro,
                    roomRule: updated.roomRule,
                    roomBackground: updated.roomBackground,
                    freeMic: updated.freeMic,
                    isCommentsClosed: updated.isCommentsClosed,
                    hasPassword: updated.hasPassword,
                  );
                });
              }
              _broadcastRoomSettingsUpdate(updated);
            },
          ),
        ),
      ),
    );
  }

  void _broadcastRoomSettingsUpdate(RoomModel room) {
    _controller?.sendRoomMessage({
      'type': 'roomSettingsUpdate',
      'data': {
        'room_name': room.roomName,
        'room_cover': room.roomCover,
        'room_intro': room.roomIntro,
        'room_rule': room.roomRule,
        'room_background': room.roomBackground,
        'free_mic': room.freeMic,
        'is_comment_closed': room.isCommentsClosed,
        'has_password': room.hasPassword,
      },
    });
  }

  void _handleRoomSettingsUpdateRtm(Map<String, dynamic> data) {
    if (!mounted || _room == null) return;
    setState(() {
      _room = _room!.copyWith(
        roomName: data['room_name']?.toString(),
        roomCover: data['room_cover']?.toString(),
        roomIntro: data['room_intro']?.toString(),
        roomRule: data['room_rule']?.toString(),
        roomBackground: data['room_background']?.toString(),
        freeMic: data['free_mic'] as bool?,
        isCommentsClosed: data['is_comment_closed'] as bool?,
        hasPassword: data['has_password'] as bool?,
      );
    });
  }

  void _showAdmins() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<RoomManagementBloc>()
          ..add(LoadAdminsEvent(roomId: widget.roomId)),
        child: RoomAdminSheet(roomId: widget.roomId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _room == null) {
      final s = RoomStrings.of(context);
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? s.error),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => AudioRoomAppOverlay.closeRoom(),
                child: Text(s.back),
              ),
            ],
          ),
        ),
      );
    }

    final room = _room!;
    final streamConfig = room.streamConfig;
    final config = AppConfigProvider.instance;

    final streamAppId = streamConfig?['app_id']?.toString() ?? '';
    final streamSecret = streamConfig?['server_secret']?.toString() ?? '';
    final appId = streamAppId.isNotEmpty ? streamAppId : config.utdStreamAppId;
    final serverSecret = streamSecret.isNotEmpty
        ? streamSecret
        : config.utdStreamServerSecret;

    if (appId.isEmpty || serverSecret.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(RoomStrings.of(context).streamConfigMissing)),
      );
    }

    final userData = CacheManager.getUserData();
    final userId = userData?['id']?.toString() ?? '';
    final userName = userData?['name']?.toString() ?? '';
    final userAvatar = userData?['avatar']?.toString() ?? '';

    final locale = Localizations.localeOf(context).languageCode;
    final kitStrings = locale == 'ar'
        ? UTDRoomStrings.ar()
        : UTDRoomStrings.en();

    Widget audioRoomWidget = UTDAudioRoom(
      appId: appId,
      serverSecret: serverSecret,
      userId: userId,
      userName: userName,
      roomId: room.id.toString(),
      roomOwnerId: room.ownerId.toString(),
      layoutMode: room.mode.toString(),
      config: UTDAudioRoomConfig(
        userInRoomAttributes: {'avatar': userAvatar, 'name': userName},
        backgroundWidget: RoomBackgroundWidget(
          backgroundUrl: room.roomBackground,
        ),
        headerWidget: _controller != null
            ? RoomHeaderWidget(
                room: room,
                controller: _controller!,
                onExit: _exitRoom,
                onMinimize: _minimizeRoom,
                onAdminsTap: _showAdmins,
                onSettingsTap: () => _openSettings(room),
              )
            : const SizedBox.shrink(),
        controlsBarWidget: _controller != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...AudioRoomFeature.registeredPlugins
                      .map((p) => p.buildControlsWidget(context, room.id))
                      .where((w) => w != null)
                      .cast<Widget>(),
                  Expanded(child: RoomControlsBar(controller: _controller!)),
                ],
              )
            : const SizedBox.shrink(),
        messagesWidget: _controller != null
            ? RoomMessagesWidget(controller: _controller!)
            : const SizedBox.shrink(),
        avatarBuilder: _controller != null
            ? (userId, size, attributes, isMuted, seatIndex, userName) =>
                  SeatAvatarWidget(
                    userId: userId,
                    size: size,
                    attributes: attributes,
                    isMuted: isMuted,
                    seatIndex: seatIndex,
                    userName: userName,
                    controller: _controller!,
                    roomId: room.id,
                  )
            : null,
        emptySeatBuilder: (index, size) {
          if (index == 0) {
            return LockedSeatWidget(index: index, size: size);
          }
          return EmptySeatWidget(index: index, size: size);
        },
        lockedSeatBuilder: (index, size) =>
            LockedSeatWidget(index: index, size: size),
      ),
      onSeatTap: _controller != null
          ? (index, seat) => handleSeatTap(
              context,
              controller: _controller!,
              seatIndex: index,
              seat: seat,
              localUserId: userId,
              isOwner: room.ownerId.toString() == userId,
              roomId: widget.roomId,
            )
          : null,
      onControllerReady: (controller) {
        controller.onInvitationUI = (data) async {
          if (!mounted) return false;
          return showSpeakerInvitationDialog(
            context,
            data,
            controller: controller,
          );
        };
        controller.onBanned = (notice) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                notice.reason ?? RoomStrings.of(context).bannedFromRoom,
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          _exitRoom();
        };
        controller.minimize.configure(
          UTDMinimizeConfig(
            roomImage: _room?.roomCover,
            onClose: () => _exitRoom(),
          ),
        );
        AudioRoomFeature.instance?.setActiveRoom(
          controller,
          _room!,
          widget.roomId,
        );
        _listenParticipantEvents(controller);
        _listenPluginMessages(controller);
        for (final plugin in AudioRoomFeature.registeredPlugins) {
          plugin.onControllerReady(controller);
        }
        PipManager.instance.enableAutoPip();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          UTDMiniOverlayMachine.instance.changeState(
            UTDMiniOverlayState.inAudioRoom,
          );
          if (mounted) setState(() => _controller = controller);
        });
      },
      onConnectionChanged: (isConnected) {
        if (!isConnected && mounted) {
          _exitRoom();
        }
      },
      modes: _buildModes(),
    );

    if (_controller != null) {
      audioRoomWidget = UTDRoomScope(
        theme: const UTDRoomTheme(),
        strings: kitStrings,
        controller: _controller!,
        showSeatNames: true,
        hostSeatIndex: 0,
        roomOwnerId: room.ownerId.toString(),
        child: audioRoomWidget,
      );
    }

    return audioRoomWidget;
  }

  List<UTDRoomMode> _buildModes() {
    return const [
      UTDRoomMode(
        id: '9',
        seatCount: 9,
        rows: [
          [0],
          [1, 2, 3, 4],
          [5, 6, 7, 8],
        ],
      ),
      UTDRoomMode(
        id: '7',
        seatCount: 7,
        rows: [
          [0],
          [1, 2, 3],
          [4, 5, 6],
        ],
      ),
      UTDRoomMode(
        id: '8',
        seatCount: 8,
        rows: [
          [0, 1],
          [2, 3, 4],
          [5, 6, 7],
        ],
      ),
      UTDRoomMode(
        id: '12',
        seatCount: 12,
        rows: [
          [0, 1, 2],
          [3, 4, 5],
          [6, 7, 8],
          [9, 10, 11],
        ],
      ),
      UTDRoomMode(
        id: '16',
        seatCount: 16,
        rows: [
          [0, 1, 2, 3],
          [4, 5, 6, 7],
          [8, 9, 10, 11],
          [12, 13, 14, 15],
        ],
      ),
      UTDRoomMode(
        id: '22',
        seatCount: 22,
        rows: [
          [0, 1, 2, 3, 4],
          [5, 6, 7, 8, 9],
          [10, 11, 12, 13, 14],
          [15, 16, 17, 18, 19],
          [20, 21],
        ],
      ),
      UTDRoomMode(
        id: '2',
        seatCount: 2,
        rows: [
          [0, 1],
        ],
      ),
    ];
  }
}
