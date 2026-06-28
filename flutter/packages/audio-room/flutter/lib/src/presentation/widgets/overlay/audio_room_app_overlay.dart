import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../audio_room_feature.dart';
import '../../../data/audio_room_api_service.dart';
import '../../../data/audio_room_remote_datasource.dart';
import '../../../data/pip_manager.dart';
import '../../../domain/audio_room_repository.dart';
import '../../../data/audio_room_repository_impl.dart';
import '../../../domain/room_model.dart';
import '../../bloc/admin/admin_bloc.dart';
import '../../bloc/blacklist/blacklist_bloc.dart';
import '../../bloc/room_management/room_management_bloc.dart';
import '../../view/audio_room_page.dart';
import 'audio_room_mini_overlay.dart';
import 'audio_room_pip_view.dart';
import 'pip_permission_dialog.dart';
import '../shared/exit_dialog_option.dart';

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

  static VoidCallback? onRoomClosed;

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
            ExitDialogOption(
              icon: Icons.picture_in_picture_alt,
              label: isAr ? 'تصغير' : 'Minimize',
              color: Colors.blue,
              onTap: () {
                Navigator.of(ctx).pop();
                _minimizeRoom();
              },
            ),
            ExitDialogOption(
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

  Future<bool> _showPipPermissionDialog() {
    final navigatorContext = _innerNavigatorKey.currentContext;
    if (navigatorContext == null) return Future.value(false);
    return showPipPermissionDialog(navigatorContext);
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
        BlocProvider(
          create: (_) => AdminBloc(repository: repository),
        ),
        BlocProvider(
          create: (_) => BlacklistBloc(repository: repository),
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
    AudioRoomAppOverlay.onRoomClosed?.call();
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
                  AudioRoomPipView(
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
                  AudioRoomMiniOverlay(onClose: _closeRoom),
              ],
            );
          },
        );
      },
    );
  }
}
