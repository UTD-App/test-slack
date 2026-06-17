import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../audio_room_feature.dart';
import '../../data/audio_room_api_service.dart';
import '../../data/audio_room_remote_datasource.dart';
import '../../data/pip_manager.dart';
import '../../domain/audio_room_repository.dart';
import '../../domain/room_model.dart';
import '../bloc/room_management_bloc.dart';
import '../view/audio_room_page.dart';

class AudioRoomAppOverlay extends StatefulWidget {
  final Widget child;
  final GoRouter router;

  const AudioRoomAppOverlay({
    super.key,
    required this.child,
    required this.router,
  });

  static _AudioRoomAppOverlayState? _state;

  static void openRoom(int roomId, {RoomModel? verifiedRoom}) {
    _state?._openRoom(roomId, verifiedRoom: verifiedRoom);
  }

  static void closeRoom() {
    _state?._closeRoom();
  }

  @override
  State<AudioRoomAppOverlay> createState() => _AudioRoomAppOverlayState();
}

class _AudioRoomAppOverlayState extends State<AudioRoomAppOverlay>
    with WidgetsBindingObserver {
  Widget? _roomPage;
  int? _activeRoomId;
  List<Page<dynamic>>? _pages;
  final _innerNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AudioRoomAppOverlay._state = this;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (AudioRoomAppOverlay._state == this) {
      AudioRoomAppOverlay._state = null;
    }
    super.dispose();
  }

  static const _pipPermissionKey = 'audio_room_pip_permission_granted';

  @override
  Future<bool> didPopRoute() async {
    final state = UTDMiniOverlayMachine.instance.stateNotifier.value;
    if (state != UTDMiniOverlayState.inAudioRoom || _roomPage == null) {
      return false;
    }
    if (_innerNavigatorKey.currentState?.canPop() ?? false) {
      _innerNavigatorKey.currentState!.pop();
      return true;
    }
    _showExitOrMinimizeDialog();
    return true;
  }

  void _showExitOrMinimizeDialog() {
    final navigatorContext = _innerNavigatorKey.currentContext;
    if (navigatorContext == null) return;
    final isAr = Localizations.localeOf(navigatorContext).languageCode == 'ar';

    showDialog(
      context: navigatorContext,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ExitDialogOption(
              icon: Icons.picture_in_picture_alt,
              label: isAr ? 'تصغير' : 'Minimize',
              color: Colors.blue,
              onTap: () {
                Navigator.of(ctx).pop();
                _minimizeRoom();
              },
            ),
            _ExitDialogOption(
              icon: Icons.exit_to_app,
              label: isAr ? 'مغادرة' : 'Leave',
              color: Colors.red,
              onTap: () {
                Navigator.of(ctx).pop();
                _exitRoomFromOverlay();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _minimizeRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final granted = prefs.getBool(_pipPermissionKey) ?? false;

    if (!granted) {
      final approved = await _showPipPermissionDialog();
      if (!approved) return;
      await prefs.setBool(_pipPermissionKey, true);
    }

    UTDMiniOverlayMachine.instance.changeState(UTDMiniOverlayState.minimizing);
  }

  Future<bool> _showPipPermissionDialog() async {
    final navigatorContext = _innerNavigatorKey.currentContext;
    if (navigatorContext == null) return false;

    final result = await showGeneralDialog<bool>(
      context: navigatorContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        );
      },
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF32e5ac).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_in_picture_alt_rounded,
                    color: Color(0xFF32e5ac),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'وضع التصغير',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.withValues(alpha: 0.1)),
                const SizedBox(height: 10),
                Text(
                  'هل توافق على تشغيل الروم في الخلفية عند التصغير؟\n'
                  'الروم هتفضل شغاله وهتقدر ترجعلها في أي وقت.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(navigatorContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'لا',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(navigatorContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF32e5ac),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'موافق',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }

  void _exitRoomFromOverlay() async {
    final feature = AudioRoomFeature.instance;
    final ctrl = feature?.activeController;
    if (ctrl != null) {
      await ctrl.leave();
    }
    feature?.clearActiveRoom();
    PipManager.instance.disableAutoPip();
    UTDMiniOverlayMachine.instance.changeState(UTDMiniOverlayState.idle);
    AudioRoomAppOverlay.closeRoom();
  }

  void _openRoom(int roomId, {RoomModel? verifiedRoom}) {
    if (_activeRoomId == roomId && _roomPage != null) {
      UTDMiniOverlayMachine.instance
          .changeState(UTDMiniOverlayState.inAudioRoom);
      setState(() {});
      return;
    }

    final repository = AudioRoomRepositoryImpl(
      remoteDataSource: AudioRoomRemoteDataSourceImpl(
        apiService: AudioRoomApiService(),
      ),
    );

    _activeRoomId = roomId;
    _roomPage = MultiBlocProvider(
      providers: [
        RepositoryProvider<AudioRoomRepository>.value(value: repository),
        BlocProvider(
          create: (_) => RoomManagementBloc(repository: repository),
        ),
      ],
      child: AudioRoomPage(
        roomId: roomId,
        verifiedRoom: verifiedRoom,
        router: widget.router,
      ),
    );
    _pages = [MaterialPage(key: ValueKey(roomId), child: _roomPage!)];

    UTDMiniOverlayMachine.instance
        .changeState(UTDMiniOverlayState.inAudioRoom);
    setState(() {});
  }

  void _closeRoom() {
    _activeRoomId = null;
    _roomPage = null;
    _pages = null;
    setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PipManager.instance.isInPip,
      builder: (_, isInPip, __) {
        return ValueListenableBuilder<UTDMiniOverlayState>(
          valueListenable: UTDMiniOverlayMachine.instance.stateNotifier,
          builder: (_, state, __) {
            final showPip = isInPip &&
                AudioRoomFeature.instance?.activeController != null;

            return Stack(
              children: [
                if (showPip)
                  _AudioRoomPipView(
                    room: AudioRoomFeature.instance!.activeRoom,
                    controller: AudioRoomFeature.instance!.activeController!,
                  )
                else
                  widget.child,
                if (_roomPage != null)
                  Offstage(
                    offstage:
                        showPip || state != UTDMiniOverlayState.inAudioRoom,
                    child: Navigator(
                      key: _innerNavigatorKey,
                      onDidRemovePage: (_) {},
                      pages: _pages!,
                    ),
                  ),
                if (!showPip && state == UTDMiniOverlayState.minimizing)
                  _AudioRoomMiniOverlay(router: widget.router),
              ],
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PiP View
// ---------------------------------------------------------------------------

class _AudioRoomPipView extends StatelessWidget {
  final dynamic room;
  final UTDRoomController controller;

  const _AudioRoomPipView({required this.room, required this.controller});

  @override
  Widget build(BuildContext context) {
    final roomName = room?.roomName as String? ?? '';
    final roomImage = room?.roomCover as String? ?? '';

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (roomImage.isNotEmpty)
              Image.network(
                roomImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: controller.activeSpeakers,
                    builder: (_, speakers, __) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: speakers.isNotEmpty
                              ? const Color(0xFF32e5ac).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              speakers.isNotEmpty
                                  ? Icons.graphic_eq_rounded
                                  : Icons.mic_off_rounded,
                              color: speakers.isNotEmpty
                                  ? const Color(0xFF32e5ac)
                                  : Colors.white54,
                              size: 18,
                            ),
                            if (speakers.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${speakers.length}',
                                style: const TextStyle(
                                  color: Color(0xFF32e5ac),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    roomName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini Overlay (in-app, draggable)
// ---------------------------------------------------------------------------

class _AudioRoomMiniOverlay extends StatefulWidget {
  final GoRouter router;
  const _AudioRoomMiniOverlay({required this.router});

  @override
  State<_AudioRoomMiniOverlay> createState() => _AudioRoomMiniOverlayState();
}

class _AudioRoomMiniOverlayState extends State<_AudioRoomMiniOverlay>
    with TickerProviderStateMixin {
  late Offset _position;
  final _size = const Size(150, 150);

  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  late final List<AnimationController> _waveControllers;

  Timer? _speakingTimer;
  final _isSpeaking = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    final screenHeight = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).size.height;
    _position = Offset(16, screenHeight - 220);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceController.forward();

    _waveControllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + (i * 200)),
      )..repeat(reverse: true);
    });

    _startSpeakingPolling();
  }

  void _startSpeakingPolling() {
    final controller = AudioRoomFeature.instance?.activeController;
    if (controller == null) return;
    _speakingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final speakers = controller.activeSpeakers.value;
      final speaking = speakers.isNotEmpty;
      if (_isSpeaking.value != speaking) {
        _isSpeaking.value = speaking;
      }
    });
  }

  @override
  void dispose() {
    _speakingTimer?.cancel();
    _entranceController.dispose();
    for (final c in _waveControllers) {
      c.dispose();
    }
    _isSpeaking.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final screen = MediaQuery.of(context).size;
      _position += details.delta;
      _position = Offset(
        _position.dx.clamp(0, screen.width - _size.width),
        _position.dy.clamp(0, screen.height - _size.height),
      );
    });
  }

  void _onRestore() {
    _entranceController.reverse().then((_) {
      if (!mounted) return;
      UTDMiniOverlayMachine.instance.changeState(
        UTDMiniOverlayState.inAudioRoom,
      );
    });
  }

  void _onClose() {
    _entranceController.reverse().then((_) async {
      final feature = AudioRoomFeature.instance;
      final controller = feature?.activeController;
      if (controller != null) {
        await controller.leave();
      }
      feature?.clearActiveRoom();
      PipManager.instance.disableAutoPip();
      UTDMiniOverlayMachine.instance.changeState(UTDMiniOverlayState.idle);
      AudioRoomAppOverlay.closeRoom();
    });
  }

  void _onMicToggle() {
    final controller = AudioRoomFeature.instance?.activeController;
    if (controller == null) return;
    final media = controller.mediaController;
    media.setMicrophoneEnabled(!media.isMicEnabled.value);
  }

  @override
  Widget build(BuildContext context) {
    final room = AudioRoomFeature.instance?.activeRoom;
    final controller = AudioRoomFeature.instance?.activeController;
    final roomImage = room?.roomCover;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, __) {
        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: _onPanUpdate,
            onTap: _onRestore,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value.clamp(0.0, 1.0),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isSpeaking,
                  builder: (_, isSpeaking, child) {
                    return _SoundWaveBorder(
                      isSpeaking: isSpeaking,
                      waveControllers: _waveControllers,
                      size: _size,
                      child: child!,
                    );
                  },
                  child: Container(
                    width: _size.width,
                    height: _size.height,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (roomImage != null && roomImage.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: roomImage,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.black.withValues(alpha: 0.88),
                              ),
                            ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: _onClose,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.call_end,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          if (controller != null &&
                              controller.localSeatIndex >= 0)
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: _MicToggleButton(
                                controller: controller,
                                onTap: _onMicToggle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SoundWaveBorder extends StatelessWidget {
  final bool isSpeaking;
  final List<AnimationController> waveControllers;
  final Size size;
  final Widget child;

  const _SoundWaveBorder({
    required this.isSpeaking,
    required this.waveControllers,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSpeaking) return child;

    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = 0; i < waveControllers.length; i++)
          AnimatedBuilder(
            animation: waveControllers[i],
            builder: (_, __) {
              final scale = 1.0 + (waveControllers[i].value * 0.04 * (i + 1));
              final opacity = (1.0 - waveControllers[i].value * 0.6).clamp(
                0.0,
                1.0,
              );
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: opacity * 0.5),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        child,
      ],
    );
  }
}

class _MicToggleButton extends StatelessWidget {
  final UTDRoomController controller;
  final VoidCallback onTap;

  const _MicToggleButton({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: controller.mutedParticipants,
      builder: (_, muted, __) {
        final localId =
            controller.roomManager.localParticipant?.identity.toString();
        final isMuted = localId != null && muted.contains(localId);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isMuted
                  ? Colors.red.withValues(alpha: 0.2)
                  : Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMuted ? Icons.mic_off : Icons.mic,
              color: isMuted ? Colors.red : Colors.green,
              size: 16,
            ),
          ),
        );
      },
    );
  }
}

class _ExitDialogOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExitDialogOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
