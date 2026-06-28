import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/shared/core/enums.dart';

import 'package:utd_app/localization/localization.dart';

import 'package:audio_room/src/audio_room_strings.dart';
import '../widgets/overlay/audio_room_app_overlay.dart';
import '../../audio_room_feature.dart';
import '../../data/pip_manager.dart';
import '../../plugin_setting_row.dart';
import '../../domain/room_model.dart';
import '../bloc/room_management/room_management_bloc.dart';
import '../widgets/room/customize/room_edit_text_sheet.dart';
import '../widgets/room/customize/room_password_dialog.dart';
import '../widgets/room/shared/room_theme.dart';
import '../widgets/settings/setting_row.dart';
import '../widgets/settings/text_setting_row.dart';
import 'room_delete_dialog.dart';
import 'room_settings_seat_icons.dart';

class RoomSettingsPage extends StatefulWidget {
  final RoomModel room;
  final void Function(RoomModel updatedRoom)? onUpdated;

  const RoomSettingsPage({super.key, required this.room, this.onUpdated});

  @override
  State<RoomSettingsPage> createState() => _RoomSettingsPageState();
}

class _RoomSettingsPageState extends State<RoomSettingsPage> {
  late bool _isCommentsClosed;
  late bool _hasPassword;
  File? _coverImage;
  String? _currentName;
  String? _currentIntro;
  String? _currentRule;
  String? _currentEmptySeatIcon;
  String? _currentLockedSeatIcon;
  File? _emptySeatIconFile;
  File? _lockedSeatIconFile;

  bool get _canEdit =>
      widget.room.isOwner == true || widget.room.isAdmin == true;

  @override
  void initState() {
    super.initState();
    _isCommentsClosed = widget.room.isCommentsClosed;
    _hasPassword = widget.room.hasPassword;
    _currentName = widget.room.roomName;
    _currentIntro = widget.room.roomIntro;
    _currentRule = widget.room.roomRule;
    _currentEmptySeatIcon = widget.room.emptySeatIcon;
    _currentLockedSeatIcon = widget.room.lockedSeatIcon;
  }

  void _save({
    String? name,
    String? intro,
    String? rule,
    bool? isCommentsClosed,
    bool? freeMic,
    File? cover,
    File? emptySeatIcon,
    File? lockedSeatIcon,
    String? emptySeatIconPreset,
    String? lockedSeatIconPreset,
  }) {
    context.read<RoomManagementBloc>().add(
      UpdateRoomEvent(
        roomId: widget.room.id,
        name: name,
        intro: intro,
        rule: rule,
        isCommentsClosed: isCommentsClosed,
        freeMic: freeMic,
        cover: cover,
        emptySeatIcon: emptySeatIcon,
        lockedSeatIcon: lockedSeatIcon,
        emptySeatIconPreset: emptySeatIconPreset,
        lockedSeatIconPreset: lockedSeatIconPreset,
      ),
    );
  }

  Future<void> _pickCover() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: RoomTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: RoomTheme.textPrimary),
              title: Text(
                context.tr(AudioRoomKeys.takePhoto),
                style: const TextStyle(color: RoomTheme.textPrimary),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: RoomTheme.textPrimary),
              title: Text(
                context.tr(AudioRoomKeys.chooseFromGallery),
                style: const TextStyle(color: RoomTheme.textPrimary),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    await PipManager.instance.disableAutoPip();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 800);
    await PipManager.instance.enableAutoPip();
    if (image != null) {
      final file = File(image.path);
      setState(() => _coverImage = file);
      _save(cover: file);
    }
  }

  void _confirmDelete() {
    showDeleteRoomConfirmDialog(
      context,
      onConfirm: () {
        context.read<RoomManagementBloc>().add(
          DeleteRoomEvent(roomId: widget.room.id),
        );
      },
    );
  }

  Future<void> _onPasswordToggle(bool value) async {
    if (value) {
      setState(() => _hasPassword = true);
      final password = await showRoomPasswordDialog(context);
      if (password == null) {
        if (mounted) setState(() => _hasPassword = false);
        return;
      }
      if (!mounted) return;
      context.read<RoomManagementBloc>().add(
        UpdateRoomEvent(roomId: widget.room.id, password: password),
      );
    } else {
      final confirmed = await showRemovePasswordDialog(context);
      if (!confirmed || !mounted) return;
      setState(() => _hasPassword = false);
      context.read<RoomManagementBloc>().add(
        RemovePasswordEvent(roomId: widget.room.id),
      );
    }
  }

  Widget _strip() => Container(height: 8.h, color: RoomTheme.stripColor);

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16, color: RoomTheme.dividerColor);

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RoomManagementBloc, RoomManagementState>(
          listenWhen: (prev, curr) => prev.updateState != curr.updateState,
          listener: (context, state) {
            if (state.updateState == RequestState.loaded) {
              if (state.updatedRoom != null) {
                widget.onUpdated?.call(state.updatedRoom!);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr(AudioRoomKeys.saved)),
                  duration: const Duration(seconds: 1),
                ),
              );
            } else if (state.updateState == RequestState.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? context.tr(AudioRoomKeys.roomError))),
              );
            }
          },
        ),
        BlocListener<RoomManagementBloc, RoomManagementState>(
          listenWhen: (prev, curr) => prev.deleteState != curr.deleteState,
          listener: (context, state) {
            if (state.deleteState == RequestState.loaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr(AudioRoomKeys.roomDeleted))),
              );
              AudioRoomAppOverlay.closeRoom();
            } else if (state.deleteState == RequestState.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? context.tr(AudioRoomKeys.deleteRoomFailed))),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: RoomTheme.bgDark,
        appBar: AppBar(
          title: Text(context.tr(AudioRoomKeys.roomInfo)),
          centerTitle: true,
          backgroundColor: RoomTheme.bgDark,
          foregroundColor: RoomTheme.textPrimary,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _strip(),

              SettingRow(
                title: context.tr(AudioRoomKeys.roomImage),
                onTap: _canEdit ? _pickCover : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 55.r,
                      height: 55.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: RoomTheme.bgDark,
                        image: _coverImage != null
                            ? DecorationImage(
                                image: FileImage(_coverImage!),
                                fit: BoxFit.cover,
                              )
                            : widget.room.roomCover != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  widget.room.roomCover!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          _coverImage == null && widget.room.roomCover == null
                          ? Icon(Icons.camera_alt, size: 20.r, color: RoomTheme.textSecondary)
                          : null,
                    ),
                    if (_canEdit) ...[
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_ios, color: RoomTheme.textSecondary, size: 14.r),
                    ],
                  ],
                ),
              ),

              _strip(),

              SettingRow(
                title: context.tr(AudioRoomKeys.roomNumber),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.room.numId.toString()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr(AudioRoomKeys.copied)),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.room.numId}',
                      style: TextStyle(color: RoomTheme.textSecondary, fontSize: 14.sp),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.copy, size: 16.r, color: RoomTheme.textSecondary),
                  ],
                ),
              ),

              _strip(),

              TextSettingRow(
                title: context.tr(AudioRoomKeys.roomName),
                value: _currentName,
                valueWidth: 150,
                canEdit: _canEdit,
                onTap: () => showEditTextSheet(
                  context,
                  title: context.tr(AudioRoomKeys.roomName),
                  initialValue: _currentName ?? '',
                  maxLength: 50,
                  onSave: (val) {
                    setState(() => _currentName = val);
                    _save(name: val);
                  },
                ),
              ),

              _divider(),

              TextSettingRow(
                title: context.tr(AudioRoomKeys.roomAnnouncement),
                value: _currentIntro,
                placeholder: context.tr(AudioRoomKeys.none),
                canEdit: _canEdit,
                onTap: () => showEditTextSheet(
                  context,
                  title: context.tr(AudioRoomKeys.roomAnnouncement),
                  initialValue: _currentIntro ?? '',
                  maxLines: 4,
                  maxLength: 500,
                  onSave: (val) {
                    setState(() => _currentIntro = val);
                    _save(intro: val);
                  },
                ),
              ),

              _divider(),

              TextSettingRow(
                title: context.tr(AudioRoomKeys.roomRules),
                value: _currentRule,
                placeholder: context.tr(AudioRoomKeys.none),
                canEdit: _canEdit,
                onTap: () => showEditTextSheet(
                  context,
                  title: context.tr(AudioRoomKeys.roomRules),
                  initialValue: _currentRule ?? '',
                  maxLines: 4,
                  maxLength: 500,
                  onSave: (val) {
                    setState(() => _currentRule = val);
                    _save(rule: val);
                  },
                ),
              ),

              if (_canEdit) ...[
                _strip(),

                SettingRow(
                  title: context.tr(AudioRoomKeys.password),
                  onTap: () => _onPasswordToggle(!_hasPassword),
                  trailing: CupertinoSwitch(
                    value: _hasPassword,
                    activeTrackColor: RoomTheme.accent,
                    onChanged: _onPasswordToggle,
                  ),
                ),

                _divider(),

                SettingRow(
                  title: context.tr(AudioRoomKeys.closeComments),
                  trailing: CupertinoSwitch(
                    value: _isCommentsClosed,
                    activeTrackColor: RoomTheme.accent,
                    onChanged: (v) {
                      setState(() => _isCommentsClosed = v);
                      _save(isCommentsClosed: v);
                    },
                  ),
                ),

                _strip(),

                SeatIconSettingsSection(
                  currentEmptySeatIcon: _currentEmptySeatIcon,
                  currentLockedSeatIcon: _currentLockedSeatIcon,
                  emptySeatIconFile: _emptySeatIconFile,
                  lockedSeatIconFile: _lockedSeatIconFile,
                  onSave: ({
                    File? emptySeatIcon,
                    File? lockedSeatIcon,
                    String? emptySeatIconPreset,
                    String? lockedSeatIconPreset,
                  }) {
                    _save(
                      emptySeatIcon: emptySeatIcon,
                      lockedSeatIcon: lockedSeatIcon,
                      emptySeatIconPreset: emptySeatIconPreset,
                      lockedSeatIconPreset: lockedSeatIconPreset,
                    );
                  },
                  onStateUpdate: ({
                    File? emptySeatIconFile,
                    String? emptySeatIcon,
                    File? lockedSeatIconFile,
                    String? lockedSeatIcon,
                  }) {
                    setState(() {
                      if (emptySeatIconFile != null || emptySeatIcon == null) {
                        _emptySeatIconFile = emptySeatIconFile;
                        _currentEmptySeatIcon = emptySeatIcon;
                      }
                      if (lockedSeatIconFile != null || lockedSeatIcon == null) {
                        _lockedSeatIconFile = lockedSeatIconFile;
                        _currentLockedSeatIcon = lockedSeatIcon;
                      }
                    });
                  },
                ),

                StatefulBuilder(
                  builder: (context, setPluginState) {
                    final rows = AudioRoomFeature.registeredPlugins
                        .expand((p) => p.getSettingRows(context, widget.room.id))
                        .toList();
                    return Column(
                      children: rows.expand((row) => [
                        _strip(),
                        if (row.type == PluginSettingType.toggle)
                          SettingRow(
                            title: row.title,
                            onTap: () {
                              row.onToggle?.call(!(row.currentValue ?? false));
                              setPluginState(() {});
                            },
                            trailing: Switch.adaptive(
                              value: row.currentValue ?? false,
                              onChanged: (v) {
                                row.onToggle?.call(v);
                                setPluginState(() {});
                              },
                              activeTrackColor: RoomTheme.accent,
                            ),
                          )
                        else
                          SettingRow(
                            title: row.title,
                            onTap: () {
                              row.onTap?.call();
                              setPluginState(() {});
                            },
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: RoomTheme.textSecondary,
                              size: 14.r,
                            ),
                          ),
                      ]).toList(),
                    );
                  },
                ),

                if (widget.room.isOwner == true) ...[
                  _strip(),

                  BlocBuilder<RoomManagementBloc, RoomManagementState>(
                    buildWhen: (prev, curr) =>
                        prev.deleteState != curr.deleteState,
                    builder: (context, state) {
                      final isDeleting =
                          state.deleteState == RequestState.loading;
                      return SettingRow(
                        title: context.tr(AudioRoomKeys.deleteRoom),
                        titleColor: Colors.red,
                        onTap: isDeleting ? null : _confirmDelete,
                        trailing: isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              )
                            : Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.red.withValues(alpha: 0.5),
                                size: 14.r,
                              ),
                      );
                    },
                  ),
                ],
              ],

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
