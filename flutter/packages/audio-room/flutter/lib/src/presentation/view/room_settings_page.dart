import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../widgets/audio_room_app_overlay.dart';
import '../../domain/room_model.dart';
import '../bloc/room_management_bloc.dart';
import '../widgets/room/room_edit_text_sheet.dart';
import '../widgets/room/room_password_dialog.dart';
import '../widgets/room/room_strings.dart';
import '../widgets/room/room_theme.dart';
import '../widgets/room/seat_icon_picker.dart';
import '../widgets/settings/file_icon_preview.dart';
import '../widgets/settings/setting_row.dart';
import '../widgets/settings/text_setting_row.dart';

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
    final s = RoomStrings.of(context);
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
                s.takePhoto,
                style: const TextStyle(color: RoomTheme.textPrimary),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: RoomTheme.textPrimary),
              title: Text(
                s.chooseFromGallery,
                style: const TextStyle(color: RoomTheme.textPrimary),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 800);
    if (image != null) {
      final file = File(image.path);
      setState(() => _coverImage = file);
      _save(cover: file);
    }
  }

  void _confirmDelete() {
    final s = RoomStrings.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 32.w),
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: RoomTheme.cardBg,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                    size: 28.r,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  s.deleteRoom,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: RoomTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 10.h),
                Divider(color: RoomTheme.dividerColor),
                SizedBox(height: 10.h),
                Text(
                  s.deleteRoomConfirm,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: RoomTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45.h,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: RoomTheme.textSecondary.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            s.cancel,
                            style: TextStyle(
                              color: RoomTheme.textSecondary,
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: SizedBox(
                        height: 45.h,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.read<RoomManagementBloc>().add(
                              DeleteRoomEvent(roomId: widget.room.id),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            s.delete,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
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
    final s = RoomStrings.of(context);
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
                  content: Text(s.saved),
                  duration: const Duration(seconds: 1),
                ),
              );
            } else if (state.updateState == RequestState.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? s.error)),
              );
            }
          },
        ),
        BlocListener<RoomManagementBloc, RoomManagementState>(
          listenWhen: (prev, curr) => prev.deleteState != curr.deleteState,
          listener: (context, state) {
            if (state.deleteState == RequestState.loaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.roomDeleted)),
              );
              AudioRoomAppOverlay.closeRoom();
            } else if (state.deleteState == RequestState.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? s.deleteRoomFailed)),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: RoomTheme.bgDark,
        appBar: AppBar(
          title: Text(s.roomInfo),
          centerTitle: true,
          backgroundColor: RoomTheme.bgDark,
          foregroundColor: RoomTheme.textPrimary,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _strip(),

              SettingRow(
                title: s.roomImage,
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
                title: s.roomNumber,
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.room.numId.toString()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s.copied),
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
                title: s.roomName,
                value: _currentName,
                valueWidth: 150,
                canEdit: _canEdit,
                onTap: () => showEditTextSheet(
                  context,
                  title: s.roomName,
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
                title: s.roomAnnouncement,
                value: _currentIntro,
                placeholder: s.none,
                canEdit: _canEdit,
                onTap: () => showEditTextSheet(
                  context,
                  title: s.roomAnnouncement,
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
                title: s.roomRules,
                value: _currentRule,
                placeholder: s.none,
                canEdit: _canEdit,
                onTap: () => showEditTextSheet(
                  context,
                  title: s.roomRules,
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
                  title: s.password,
                  onTap: () => _onPasswordToggle(!_hasPassword),
                  trailing: CupertinoSwitch(
                    value: _hasPassword,
                    activeTrackColor: RoomTheme.accent,
                    onChanged: _onPasswordToggle,
                  ),
                ),

                _divider(),

                SettingRow(
                  title: s.closeComments,
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

                SettingRow(
                  title: s.emptySeatIcon,
                  onTap: () async {
                    final result = await showSeatIconPicker(
                      context,
                      currentValue: _currentEmptySeatIcon,
                      iconType: SeatIconType.empty,
                    );
                    if (result == null) return;
                    if (result.type == SeatIconChoiceType.custom) {
                      setState(() {
                        _emptySeatIconFile = result.file;
                        _currentEmptySeatIcon = null;
                      });
                      _save(emptySeatIcon: result.file);
                    } else if (result.type == SeatIconChoiceType.preset) {
                      setState(() {
                        _emptySeatIconFile = null;
                        _currentEmptySeatIcon = result.presetName;
                      });
                      _save(emptySeatIconPreset: result.presetName);
                    } else {
                      setState(() {
                        _emptySeatIconFile = null;
                        _currentEmptySeatIcon = null;
                      });
                      _save(emptySeatIconPreset: '');
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _emptySeatIconFile != null
                          ? FileIconPreview(file: _emptySeatIconFile!, size: 36.r)
                          : SeatIconPreview(
                              currentValue: _currentEmptySeatIcon,
                              size: 36.r,
                              iconType: SeatIconType.empty,
                            ),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_ios, color: RoomTheme.textSecondary, size: 14.r),
                    ],
                  ),
                ),

                _divider(),

                SettingRow(
                  title: s.lockedSeatIcon,
                  onTap: () async {
                    final result = await showSeatIconPicker(
                      context,
                      currentValue: _currentLockedSeatIcon,
                      iconType: SeatIconType.locked,
                    );
                    if (result == null) return;
                    if (result.type == SeatIconChoiceType.custom) {
                      setState(() {
                        _lockedSeatIconFile = result.file;
                        _currentLockedSeatIcon = null;
                      });
                      _save(lockedSeatIcon: result.file);
                    } else if (result.type == SeatIconChoiceType.preset) {
                      setState(() {
                        _lockedSeatIconFile = null;
                        _currentLockedSeatIcon = result.presetName;
                      });
                      _save(lockedSeatIconPreset: result.presetName);
                    } else {
                      setState(() {
                        _lockedSeatIconFile = null;
                        _currentLockedSeatIcon = null;
                      });
                      _save(lockedSeatIconPreset: '');
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _lockedSeatIconFile != null
                          ? FileIconPreview(file: _lockedSeatIconFile!, size: 36.r)
                          : SeatIconPreview(
                              currentValue: _currentLockedSeatIcon,
                              size: 36.r,
                              iconType: SeatIconType.locked,
                            ),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_ios, color: RoomTheme.textSecondary, size: 14.r),
                    ],
                  ),
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
                        title: s.deleteRoom,
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
