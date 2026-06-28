import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../audio_room_feature.dart';
import '../../../data/pip_manager.dart';
import '../shared/mic_toggle_button.dart';
import '../room/shared/sound_wave_border.dart';

class AudioRoomMiniOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const AudioRoomMiniOverlay({super.key, required this.onClose});

  @override
  State<AudioRoomMiniOverlay> createState() => _AudioRoomMiniOverlayState();
}

class _AudioRoomMiniOverlayState extends State<AudioRoomMiniOverlay>
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
      widget.onClose();
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
                    return SoundWaveBorder(
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
                              child: MicToggleButton(
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
