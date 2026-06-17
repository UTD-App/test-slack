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

const _bgDark = Color(0xFF1A1028);
const _cardBg = Color(0xFF2A1840);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFB8A5CC);
const _accent = Color(0xFFB44AFF);
const _dividerColor = Color(0xFF3D2560);
const _stripColor = Color(0xFF120B1E);

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
  }

  void _save({
    String? name,
    String? intro,
    String? rule,
    bool? isCommentsClosed,
    bool? freeMic,
    File? cover,
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
      ),
    );
  }

  Future<void> _pickCover() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _textPrimary),
              title: const Text(
                'التقاط صورة',
                style: TextStyle(color: _textPrimary),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _textPrimary),
              title: const Text(
                'اختيار من المعرض',
                style: TextStyle(color: _textPrimary),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('حذف الغرفة', style: TextStyle(color: _textPrimary)),
        content: const Text(
          'هل أنت متأكد من حذف هذه الغرفة؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<RoomManagementBloc>().add(
                DeleteRoomEvent(roomId: widget.room.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
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

  Widget _strip() => Container(height: 8.h, color: _stripColor);

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16, color: _dividerColor);

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
                const SnackBar(
                  content: Text('تم الحفظ'),
                  duration: Duration(seconds: 1),
                ),
              );
            } else if (state.updateState == RequestState.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? 'حدث خطأ')),
              );
            }
          },
        ),
        BlocListener<RoomManagementBloc, RoomManagementState>(
          listenWhen: (prev, curr) => prev.deleteState != curr.deleteState,
          listener: (context, state) {
            if (state.deleteState == RequestState.loaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف الغرفة')),
              );
              AudioRoomAppOverlay.closeRoom();
            } else if (state.deleteState == RequestState.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? 'فشل حذف الغرفة')),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          title: const Text('معلومات الغرفة'),
          centerTitle: true,
          backgroundColor: _bgDark,
          foregroundColor: _textPrimary,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _strip(),

              _SettingRow(
                title: 'صورة الغرفة',
                onTap: _canEdit ? _pickCover : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 55.r,
                      height: 55.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: _bgDark,
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
                          ? Icon(Icons.camera_alt, size: 20.r, color: _textSecondary)
                          : null,
                    ),
                    if (_canEdit) ...[
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_ios, color: _textSecondary, size: 14.r),
                    ],
                  ],
                ),
              ),

              _strip(),

              _SettingRow(
                title: 'رقم الغرفة',
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.room.numId.toString()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم النسخ'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.room.numId}',
                      style: TextStyle(color: _textSecondary, fontSize: 14.sp),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.copy, size: 16.r, color: _textSecondary),
                  ],
                ),
              ),

              _strip(),

              _TextSettingRow(
                title: 'اسم الغرفة',
                value: _currentName,
                valueWidth: 150,
                canEdit: _canEdit,
                onTap: () => showEditTextSheet(
                  context,
                  title: 'اسم الغرفة',
                  initialValue: _currentName ?? '',
                  maxLength: 50,
                  onSave: (val) {
                    setState(() => _currentName = val);
                    _save(name: val);
                  },
                ),
              ),

              _divider(),

              _TextSettingRow(
                title: 'إعلان الغرفة',
                value: _currentIntro,
                placeholder: 'لا يوجد',
                canEdit: _canEdit,
                onTap: () => showEditTextSheet(
                  context,
                  title: 'إعلان الغرفة',
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

              _TextSettingRow(
                title: 'قوانين الغرفة',
                value: _currentRule,
                placeholder: 'لا يوجد',
                canEdit: _canEdit,
                onTap: () => showEditTextSheet(
                  context,
                  title: 'قوانين الغرفة',
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

                _SettingRow(
                  title: 'كلمة المرور',
                  onTap: () => _onPasswordToggle(!_hasPassword),
                  trailing: CupertinoSwitch(
                    value: _hasPassword,
                    activeTrackColor: _accent,
                    onChanged: _onPasswordToggle,
                  ),
                ),

                _divider(),

                _SettingRow(
                  title: 'إغلاق التعليقات',
                  trailing: CupertinoSwitch(
                    value: _isCommentsClosed,
                    activeTrackColor: _accent,
                    onChanged: (v) {
                      setState(() => _isCommentsClosed = v);
                      _save(isCommentsClosed: v);
                    },
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
                      return _SettingRow(
                        title: 'حذف الغرفة',
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

class _SettingRow extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.title,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        color: _bgDark,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                color: titleColor ?? _textPrimary,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _TextSettingRow extends StatelessWidget {
  final String title;
  final String? value;
  final String placeholder;
  final double valueWidth;
  final bool canEdit;
  final VoidCallback? onTap;

  const _TextSettingRow({
    required this.title,
    this.value,
    this.placeholder = '',
    this.valueWidth = 100,
    this.canEdit = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      title: title,
      onTap: canEdit ? onTap : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: valueWidth.w,
            child: Text(
              value ?? placeholder,
              style: TextStyle(color: _textSecondary, fontSize: 14.sp),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
          if (canEdit) ...[
            SizedBox(width: 4.w),
            Icon(Icons.arrow_forward_ios, color: _textSecondary, size: 14.r),
          ],
        ],
      ),
    );
  }
}
