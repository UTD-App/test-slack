import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../audio_room_feature.dart';
import '../widgets/audio_room_app_overlay.dart';
import '../../domain/room_model.dart';
import '../../plugin_setting_row.dart';
import '../bloc/room_management_bloc.dart';

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
  late bool _freeMic;
  late bool _hasPassword;
  File? _coverImage;
  String? _currentName;
  String? _currentIntro;
  String? _currentRule;

  bool get _canEdit => widget.room.isOwner == true || widget.room.isAdmin == true;

  List<PluginSettingRow> get _pluginSettingRows {
    final plugins = AudioRoomFeature.registeredPlugins;
    final rows = <PluginSettingRow>[];
    for (final plugin in plugins) {
      rows.addAll(plugin.getSettingRows(context, widget.room.id));
    }
    return rows;
  }

  Widget _buildPluginRow(PluginSettingRow row) {
    switch (row.type) {
      case PluginSettingType.toggle:
        return _SettingRow(
          title: row.title,
          trailing: row.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : CupertinoSwitch(
                  value: row.currentValue ?? false,
                  activeTrackColor: _accent,
                  onChanged: (v) {
                    row.onToggle?.call(v);
                    setState(() {});
                  },
                ),
        );
      case PluginSettingType.action:
        return _SettingRow(
          title: row.title,
          onTap: row.isLoading
              ? null
              : () {
                  row.onTap?.call();
                  setState(() {});
                },
          trailing: row.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.arrow_forward_ios,
                  color: _textSecondary, size: 14.r),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _isCommentsClosed = widget.room.isCommentsClosed;
    _freeMic = widget.room.freeMic;
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
    context.read<RoomManagementBloc>().add(UpdateRoomEvent(
          roomId: widget.room.id,
          name: name,
          intro: intro,
          rule: rule,
          isCommentsClosed: isCommentsClosed,
          freeMic: freeMic,
          cover: cover,
        ));
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
              title: const Text('التقاط صورة',
                  style: TextStyle(color: _textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _textPrimary),
              title: const Text('اختيار من المعرض',
                  style: TextStyle(color: _textPrimary)),
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

  void _editText({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
    int maxLines = 1,
    int? maxLength,
  }) {
    final controller = TextEditingController(text: initialValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16.w,
          right: 16.w,
          top: 16.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary)),
                TextButton(
                  onPressed: () {
                    onSave(controller.text.trim());
                    Navigator.pop(ctx);
                  },
                  child: Text('حفظ', style: TextStyle(color: _accent)),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              maxLines: maxLines,
              maxLength: maxLength,
              autofocus: true,
              style: const TextStyle(color: _textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: _bgDark,
                counterStyle: const TextStyle(color: _textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
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

  void _showPasswordDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('كلمة مرور الغرفة',
            style: TextStyle(color: _textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: _textPrimary),
          decoration: InputDecoration(
            hintText: 'ادخل كلمة المرور (6 أرقام)',
            hintStyle: const TextStyle(color: _textSecondary),
            counterStyle: const TextStyle(color: _textSecondary),
            filled: true,
            fillColor: _bgDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _hasPassword = false);
            },
            child: const Text('إلغاء', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<RoomManagementBloc>().add(UpdateRoomEvent(
                      roomId: widget.room.id,
                      password: controller.text.trim(),
                    ));
                Navigator.pop(ctx);
              }
            },
            child: Text('تأكيد', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  void _onPasswordToggle(bool value) {
    if (value) {
      setState(() => _hasPassword = true);
      _showPasswordDialog();
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _cardBg,
          title: const Text('إزالة كلمة المرور',
              style: TextStyle(color: _textPrimary)),
          content: const Text(
            'هل تريد إزالة كلمة المرور من الغرفة؟',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إلغاء', style: TextStyle(color: _textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _hasPassword = false);
                context.read<RoomManagementBloc>().add(
                      RemovePasswordEvent(roomId: widget.room.id),
                    );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('إزالة'),
            ),
          ],
        ),
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

              // --- صورة الغرفة ---
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
                                        widget.room.roomCover!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child:
                          _coverImage == null && widget.room.roomCover == null
                              ? Icon(Icons.camera_alt,
                                  size: 20.r, color: _textSecondary)
                              : null,
                    ),
                    if (_canEdit) ...[
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_ios,
                          color: _textSecondary, size: 14.r),
                    ],
                  ],
                ),
              ),

              _strip(),

              // --- رقم الغرفة ---
              _SettingRow(
                title: 'رقم الغرفة',
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: widget.room.numId.toString()));
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
                      style:
                          TextStyle(color: _textSecondary, fontSize: 14.sp),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.copy, size: 16.r, color: _textSecondary),
                  ],
                ),
              ),

              _strip(),

              // --- اسم الغرفة ---
              _SettingRow(
                title: 'اسم الغرفة',
                onTap: _canEdit
                    ? () => _editText(
                          title: 'اسم الغرفة',
                          initialValue: _currentName ?? '',
                          maxLength: 50,
                          onSave: (val) {
                            setState(() => _currentName = val);
                            _save(name: val);
                          },
                        )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 150.w,
                      child: Text(
                        _currentName ?? '',
                        style: TextStyle(
                            color: _textSecondary, fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    if (_canEdit) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_forward_ios,
                          color: _textSecondary, size: 14.r),
                    ],
                  ],
                ),
              ),

              _divider(),

              // --- إعلان الغرفة ---
              _SettingRow(
                title: 'إعلان الغرفة',
                onTap: _canEdit
                    ? () => _editText(
                          title: 'إعلان الغرفة',
                          initialValue: _currentIntro ?? '',
                          maxLines: 4,
                          maxLength: 500,
                          onSave: (val) {
                            setState(() => _currentIntro = val);
                            _save(intro: val);
                          },
                        )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 100.w,
                      child: Text(
                        _currentIntro ?? 'لا يوجد',
                        style: TextStyle(
                            color: _textSecondary, fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    if (_canEdit) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_forward_ios,
                          color: _textSecondary, size: 14.r),
                    ],
                  ],
                ),
              ),

              _divider(),

              // --- قوانين الغرفة ---
              _SettingRow(
                title: 'قوانين الغرفة',
                onTap: _canEdit
                    ? () => _editText(
                          title: 'قوانين الغرفة',
                          initialValue: _currentRule ?? '',
                          maxLines: 4,
                          maxLength: 500,
                          onSave: (val) {
                            setState(() => _currentRule = val);
                            _save(rule: val);
                          },
                        )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 100.w,
                      child: Text(
                        _currentRule ?? 'لا يوجد',
                        style: TextStyle(
                            color: _textSecondary, fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    if (_canEdit) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_forward_ios,
                          color: _textSecondary, size: 14.r),
                    ],
                  ],
                ),
              ),

              // --- Plugin settings ---
              if (_canEdit && _pluginSettingRows.isNotEmpty) ...[
                _strip(),
                for (int i = 0; i < _pluginSettingRows.length; i++) ...[
                  _buildPluginRow(_pluginSettingRows[i]),
                  if (i < _pluginSettingRows.length - 1) _divider(),
                ],
              ],

              if (_canEdit) ...[
                _strip(),

                // --- كلمة المرور ---
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

                // --- إغلاق التعليقات ---
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

                _divider(),

                // --- مايك حر ---
                _SettingRow(
                  title: 'مايك حر',
                  trailing: CupertinoSwitch(
                    value: _freeMic,
                    activeTrackColor: _accent,
                    onChanged: (v) {
                      setState(() => _freeMic = v);
                      _save(freeMic: v);
                    },
                  ),
                ),

                if (widget.room.isOwner == true) ...[
                _strip(),

                // --- حذف الغرفة ---
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
                          : Icon(Icons.arrow_forward_ios,
                              color: Colors.red.withValues(alpha: 0.5),
                              size: 14.r),
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
            Text(title,
                style: TextStyle(
                    fontSize: 15.sp,
                    color: titleColor ?? _textPrimary)),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
