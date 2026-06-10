import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../data/pending_exit_manager.dart';
import '../../domain/audio_room_repository.dart';
import '../../domain/room_model.dart';
import '../bloc/room_management_bloc.dart';
import '../widgets/room/empty_seat_widget.dart';
import '../widgets/room/locked_seat_widget.dart';
import '../widgets/room/room_background_widget.dart';
import '../widgets/room/room_controls_bar.dart';
import '../widgets/room/room_header_widget.dart';
import '../widgets/room/room_messages_widget.dart';
import '../widgets/room/room_strings.dart';
import '../widgets/room/seat_avatar_widget.dart';
import '../widgets/room/seat_options_sheet.dart';
import '../widgets/room/speaker_invitation_dialog.dart';
import '../widgets/room_admin_sheet.dart';
import '../widgets/room_blacklist_sheet.dart';
import '../widgets/room_visitors_sheet.dart';

class AudioRoomPage extends StatefulWidget {
  final int roomId;

  const AudioRoomPage({super.key, required this.roomId});

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

  @override
  void initState() {
    super.initState();
    _flushPendingExits();
    _enterRoom();
  }

  @override
  void dispose() {
    _joinSub?.cancel();
    _leaveSub?.cancel();
    super.dispose();
  }

  Future<void> _enterRoom() async {
    final repository = context.read<AudioRoomRepository>();
    final result = await repository.enterRoom(widget.roomId);

    switch (result) {
      case Success(data: final data):
        if (data.data != null) {
          setState(() {
            _room = data.data;
            _isLoading = false;
          });
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

  Future<void> _exitRoom() async {
    if (_controller != null) {
      final userId = CacheManager.getUserData()?['id']?.toString() ?? '';
      final seatIndex =
          _controller!.seatController.getSeatIndexByUserId(userId);
      if (seatIndex >= 0) {
        await _controller!.seatController.leaveSeat(userId);
      }
    }
    final repository = context.read<AudioRoomRepository>();
    final result = await repository.exitRoom(widget.roomId);
    if (result is Failure) {
      await PendingExitManager.add(widget.roomId);
    }
    if (mounted) context.pop();
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

  void _showVisitors() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<RoomManagementBloc>()
          ..add(LoadVisitorsEvent(roomId: widget.roomId)),
        child: RoomVisitorsSheet(roomId: widget.roomId),
      ),
    );
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

  void _showBlacklist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<RoomManagementBloc>()
          ..add(LoadBlacklistEvent(roomId: widget.roomId)),
        child: RoomBlacklistSheet(roomId: widget.roomId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                onPressed: () => context.pop(),
                child: Text(s.back),
              ),
            ],
          ),
        ),
      );
    }

    final room = _room!;
    final streamConfig = room.streamConfig;
    if (streamConfig == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(RoomStrings.of(context).streamConfigMissing)),
      );
    }

    final appId = streamConfig['app_id']?.toString() ?? '';
    final serverSecret = streamConfig['server_secret']?.toString() ?? '';

    final userData = CacheManager.getUserData();
    final userId = userData?['id']?.toString() ?? '';
    final userName = userData?['name']?.toString() ?? '';
    final userAvatar = userData?['avatar']?.toString() ?? '';

    return UTDAudioRoom(
      appId: appId,
      serverSecret: serverSecret,
      userId: userId,
      userName: userName,
      roomId: room.id.toString(),
      roomOwnerId: room.ownerId.toString(),
      layoutMode: room.mode.toString(),
      config: UTDAudioRoomConfig(
        userInRoomAttributes: {
          'avatar': userAvatar,
          'name': userName,
        },
        backgroundWidget: RoomBackgroundWidget(
          backgroundUrl: room.roomBackground,
        ),
        headerWidget: _controller != null
            ? RoomHeaderWidget(
                room: room,
                controller: _controller!,
                onExit: _exitRoom,
                onVisitorsTap: _showVisitors,
                onAdminsTap: _showAdmins,
                onBlacklistTap: _showBlacklist,
                onSettingsTap: () =>
                    context.push('/rooms/${room.id}/settings'),
              )
            : const SizedBox.shrink(),
        controlsBarWidget: _controller != null
            ? RoomControlsBar(controller: _controller!)
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
                )
            : null,
        emptySeatBuilder: (index, size) {
          if (index == 0 && room.ownerId.toString() != userId) {
            return LockedSeatWidget(index: index, size: size);
          }
          return EmptySeatWidget(index: index, size: size);
        },
        lockedSeatBuilder: (index, size) => LockedSeatWidget(
          index: index,
          size: size,
        ),
      ),
      onSeatTap: _controller != null
          ? (index, seat) => handleSeatTap(
                context,
                controller: _controller!,
                seatIndex: index,
                seat: seat,
                localUserId: userId,
                isOwner: room.ownerId.toString() == userId,
              )
          : null,
      onControllerReady: (controller) {
        controller.onInvitationUI = (data) async {
          if (!mounted) return false;
          return showSpeakerInvitationDialog(context, data);
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
        _listenParticipantEvents(controller);
        WidgetsBinding.instance.addPostFrameCallback((_) {
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
  }

  List<UTDRoomMode> _buildModes() {
    return const [
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
        id: '9',
        seatCount: 9,
        rows: [
          [0],
          [1, 2, 3, 4],
          [5, 6, 7, 8],
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
