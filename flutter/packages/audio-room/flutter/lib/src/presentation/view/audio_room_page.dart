import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/config/app_config.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../audio_room_feature.dart';
import '../../data/pending_exit_manager.dart';
import '../../data/pip_manager.dart';
import '../../domain/room_model.dart';
import '../bloc/admin/admin_bloc.dart';
import '../bloc/room_management/room_management_bloc.dart';
import '../mixins/audio_room_plugin_mixin.dart';
import '../mixins/audio_room_rtm_mixin.dart';
import '../widgets/overlay/audio_room_app_overlay.dart';
import '../widgets/room/seats/empty_seat_widget.dart';
import '../widgets/room/seats/locked_seat_widget.dart';
import '../widgets/room/customize/room_background_widget.dart';
import '../widgets/room/controls/room_controls_bar.dart';
import '../widgets/room/header/room_header_widget.dart';
import 'package:utd_app/localization/localization.dart';

import 'package:audio_room/src/audio_room_strings.dart';
import '../widgets/room/messages/room_messages_widget.dart';
import '../widgets/room/seats/custom_seat_icon_widget.dart';
import '../widgets/room/seats/seat_avatar_widget.dart';
import '../widgets/room/customize/room_background_sheet.dart';
import '../widgets/room/customize/room_customize_sheet.dart';
import '../widgets/room/seats/seat_mode_sheet.dart';
import '../widgets/room/seats/seat_options_sheet.dart';
import '../widgets/room/invite/speaker_invitation_dialog.dart';
import '../widgets/shared/room_admin_sheet.dart';
import 'room_settings_page.dart';

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

class _AudioRoomPageState extends State<AudioRoomPage>
    with AudioRoomRtmMixin, AudioRoomPluginMixin {
  RoomModel? _room;
  bool _isLoading = true;
  String? _error;
  UTDRoomController? _controller;
  bool _isExiting = false;
  bool _isFavorite = false;
  VoidCallback? _commentsWatcher;

  @override
  RoomModel? get currentRoom => _room;

  @override
  set currentRoom(RoomModel? value) => _room = value;

  @override
  UTDRoomController? get roomController => _controller;

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
      if (_room?.isCommentsClosed == true) {
        _controller!.commentsLocked.value = true;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UTDMiniOverlayMachine.instance.changeState(
          UTDMiniOverlayState.inAudioRoom,
        );
        if (mounted && _controller != null) {
          listenParticipantEvents(_controller!);
          listenPluginMessages(_controller!);
          _watchCommentsLocked(_controller!);
        }
      });
    } else {
      _enterRoom();
    }
  }

  @override
  void dispose() {
    if (_commentsWatcher != null) {
      try {
        _controller?.commentsLocked.removeListener(_commentsWatcher!);
      } catch (_) {}
    }
    disposeRtm();
    super.dispose();
  }

  void _enterRoom() {
    if (widget.verifiedRoom != null) {
      setState(() {
        _room = widget.verifiedRoom;
        _isFavorite = widget.verifiedRoom!.isFavorite;
        _isLoading = false;
      });
      if (widget.verifiedRoom!.pinnedMessage != null) {
        AudioRoomFeature.instance?.pinnedMessage.value =
            widget.verifiedRoom!.pinnedMessage;
      }
      notifyPluginsEnter(widget.verifiedRoom!);
      return;
    }

    context.read<RoomManagementBloc>().add(
      EnterRoomEvent(roomId: widget.roomId),
    );
  }

  void _minimizeRoom() {
    if (_controller == null || !_controller!.isConnected) return;
    UTDMiniOverlayMachine.instance.changeState(UTDMiniOverlayState.minimizing);
  }

  void _toggleFavorite() {
    if (_room == null) return;
    setState(() => _isFavorite = !_isFavorite);
    context.read<RoomManagementBloc>().add(
      ToggleRoomFavoriteEvent(roomId: _room!.id),
    );
  }

  Future<void> _exitRoom() async {
    if (_isExiting) return;
    _isExiting = true;
    notifyPluginsExit();
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
    context.read<RoomManagementBloc>().add(
      ExitRoomEvent(roomId: widget.roomId),
    );
    AudioRoomAppOverlay.closeRoom();
  }

  void _watchCommentsLocked(UTDRoomController controller) {
    _commentsWatcher = () {
      if (!mounted || !controller.isConnected) return;
      try {
        final expected = _room?.isCommentsClosed ?? false;
        if (controller.commentsLocked.value != expected) {
          controller.commentsLocked.value = expected;
        }
      } catch (_) {}
    };
    controller.commentsLocked.addListener(_commentsWatcher!);
  }

  void _flushPendingExits() async {
    final pendingIds = await PendingExitManager.getAll();
    if (pendingIds.isEmpty || !mounted) return;
    final bloc = context.read<RoomManagementBloc>();
    for (final id in pendingIds) {
      bloc.add(ExitRoomEvent(roomId: id));
      await PendingExitManager.remove(id);
    }
  }

  void _openSettings(RoomModel room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<RoomManagementBloc>(),
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
                    roomBackground: () => updated.roomBackground,
                    freeMic: updated.freeMic,
                    isCommentsClosed: updated.isCommentsClosed,
                    hasPassword: updated.hasPassword,
                    emptySeatIcon: () => updated.emptySeatIcon,
                    lockedSeatIcon: () => updated.lockedSeatIcon,
                  );
                });
              }
              broadcastRoomSettingsUpdate(updated);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomizeSheet(
    RoomModel room,
    List<UTDRoomMode> modes,
  ) async {
    final option = await showRoomCustomizeSheet(context, isOwner: room.isOwner == true);
    if (option == null || !mounted) return;
    switch (option) {
      case RoomCustomizeOption.modes:
        showSeatModeSheet(
          context,
          currentMode: room.mode,
          modes: modes,
          onModeSelected: (mode) => _changeMode(room.id, mode),
        );
      case RoomCustomizeOption.background:
        final bgOption = await showRoomBackgroundSheet(
          context,
          hasBackground: room.roomBackground != null,
        );
        if (bgOption == null || !mounted) return;
        switch (bgOption) {
          case RoomBackgroundOption.change:
            await PipManager.instance.disableAutoPip();
            final picker = ImagePicker();
            final image = await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1920,
            );
            await PipManager.instance.enableAutoPip();
            if (image == null || !mounted) return;
            final file = File(image.path);
            context.read<RoomManagementBloc>().add(
              UpdateRoomEvent(roomId: room.id, backgroundFile: file),
            );
          case RoomBackgroundOption.reset:
            context.read<RoomManagementBloc>().add(
              UpdateRoomEvent(roomId: room.id, removeBackground: true),
            );
        }
    }
  }

  void _showAdmins() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBloc>()
          ..add(LoadAdminsEvent(roomId: widget.roomId)),
        child: RoomAdminSheet(roomId: widget.roomId),
      ),
    );
  }

  void _changeMode(int roomId, int mode) {
    final resolvedMode = _controller!.resolveMode(mode.toString());
    setState(() {
      _room = _room!.copyWith(mode: mode);
    });
    _controller?.currentMode.value = resolvedMode;

    final userId = CacheManager.getUserData()?['id']?.toString() ?? '';
    _controller?.seatController.setupSeats(
      identity: userId,
      seatCount: resolvedMode.seatCount,
      seatMode: _controller!.seatController.seatMode.value,
      modeId: mode.toString(),
    );

    broadcastRoomSettingsUpdate(_room!);
    context.read<RoomManagementBloc>().add(
      ChangeRoomModeEvent(roomId: roomId, mode: mode),
    );
  }

  List<UTDRoomMode> _buildModes() {
    return [
      const UTDRoomMode(
        id: '9',
        seatCount: 9,
        rows: [
          [0],
          [1, 2, 3, 4],
          [5, 6, 7, 8],
        ],
      ),
      ...AudioRoomFeature.instance?.modePlugins.map((p) => p.toUTDRoomMode()) ??
          const [],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomManagementBloc, RoomManagementState>(
      listenWhen: (prev, curr) => prev.enterState != curr.enterState,
      listener: (context, state) {
        if (state.enterState == RequestState.loaded &&
            state.enteredRoom != null) {
          setState(() {
            _room = state.enteredRoom;
            _isFavorite = state.enteredRoom!.isFavorite;
            _isLoading = false;
          });
          if (state.enteredRoom!.pinnedMessage != null) {
            AudioRoomFeature.instance?.pinnedMessage.value =
                state.enteredRoom!.pinnedMessage;
          }
          notifyPluginsEnter(state.enteredRoom!);
        } else if (state.enterState == RequestState.error) {
          setState(() {
            _error = state.message;
            _isLoading = false;
          });
        }
      },
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? context.tr(AudioRoomKeys.roomError)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => AudioRoomAppOverlay.closeRoom(),
                child: Text(context.tr(AudioRoomKeys.back)),
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
    final appId = streamAppId.isNotEmpty ? streamAppId : config.utdStreamAppId;

    final streamAppKey = streamConfig?['app_key']?.toString() ?? '';
    final appKey = streamAppKey.isNotEmpty
        ? streamAppKey
        : config.utdStreamAppKey;

    if (appId.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.tr(AudioRoomKeys.streamConfigMissing))),
      );
    }

    final userData = CacheManager.getUserData();
    final userId = userData?['id']?.toString() ?? '';
    final userName = userData?['name']?.toString() ?? '';
    final profile = userData?['profile'] as Map?;
    final userAvatar = profile?['image']?.toString() ?? '';

    final locale = Localizations.localeOf(context).languageCode;
    final kitStrings = locale == 'ar'
        ? UTDRoomStrings.ar()
        : UTDRoomStrings.en();
    final modes = _buildModes();

    Widget audioRoomWidget = UTDAudioRoom(
      appId: appId,
      appKey: appKey,
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
                onModeTap: () => showSeatModeSheet(
                  context,
                  currentMode: room.mode,
                  modes: modes,
                  onModeSelected: (mode) => _changeMode(room.id, mode),
                ),
                onSettingsTap: () => _openSettings(room),
                onLockCommentsToggled: (locked) {
                  setState(() {
                    _room = _room!.copyWith(isCommentsClosed: locked);
                  });
                  broadcastRoomSettingsUpdate(_room!);
                },
                isFavorite: _isFavorite,
                onFavoriteTap: _toggleFavorite,
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
                  Expanded(
                    child: RoomControlsBar(
                      controller: _controller!,
                      isOwner: room.isOwner == true,
                      isAdmin: room.isAdmin == true,
                      onModeTap: () => _showCustomizeSheet(room, modes),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
        messagesWidget: _controller != null
            ? RoomMessagesWidget(
                controller: _controller!,
                roomId: widget.roomId,
                isOwner: room.ownerId.toString() == userId,
              )
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
            if (room.lockedSeatIcon != null) {
              return CustomSeatIconWidget(
                index: index,
                size: size,
                iconValue: room.lockedSeatIcon!,
              );
            }
            return LockedSeatWidget(index: index, size: size);
          }
          if (room.emptySeatIcon != null) {
            return CustomSeatIconWidget(
              index: index,
              size: size,
              iconValue: room.emptySeatIcon!,
            );
          }
          return EmptySeatWidget(index: index, size: size);
        },
        lockedSeatBuilder: (index, size) {
          if (room.lockedSeatIcon != null) {
            return CustomSeatIconWidget(
              index: index,
              size: size,
              iconValue: room.lockedSeatIcon!,
            );
          }
          return LockedSeatWidget(index: index, size: size);
        },
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
                notice.reason ?? context.tr(AudioRoomKeys.bannedFromRoom),
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
        if (_room?.isCommentsClosed == true) {
          controller.commentsLocked.value = true;
        }
        listenParticipantEvents(controller);
        listenPluginMessages(controller);
        _watchCommentsLocked(controller);
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
      modes: modes,
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

    return BlocListener<RoomManagementBloc, RoomManagementState>(
      listenWhen: (prev, curr) => prev.updateState != curr.updateState,
      listener: (context, state) {
        if (state.updateState == RequestState.loaded &&
            state.updatedRoom != null) {
          final updated = state.updatedRoom!;
          setState(() {
            _room = _room!.copyWith(
              roomName: updated.roomName,
              roomCover: updated.roomCover,
              roomIntro: updated.roomIntro,
              roomRule: updated.roomRule,
              roomBackground: () => updated.roomBackground,
              hasPassword: updated.hasPassword,
              mode: updated.mode,
              isCommentsClosed: updated.isCommentsClosed,
              freeMic: updated.freeMic,
              emptySeatIcon: () => updated.emptySeatIcon,
              lockedSeatIcon: () => updated.lockedSeatIcon,
            );
          });
          broadcastRoomSettingsUpdate(_room!);
        }
      },
      child: audioRoomWidget,
    );
  }
}
