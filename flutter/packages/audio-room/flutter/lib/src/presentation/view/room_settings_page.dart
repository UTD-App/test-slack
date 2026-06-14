import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../domain/room_model.dart';
import '../bloc/room_management_bloc.dart';

const _bgDark = Color(0xFF1A1028);
const _cardBg = Color(0xFF2A1840);
const _cardBorder = Color(0xFF3D2560);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFB8A5CC);
const _accent = Color(0xFFB44AFF);
const _dividerColor = Color(0xFF3D2560);

class RoomSettingsPage extends StatefulWidget {
  final RoomModel room;

  const RoomSettingsPage({super.key, required this.room});

  @override
  State<RoomSettingsPage> createState() => _RoomSettingsPageState();
}

class _RoomSettingsPageState extends State<RoomSettingsPage> {
  late int _selectedMode;
  late bool _isCommentsClosed;
  late bool _freeMic;
  File? _coverImage;
  String? _currentName;
  String? _currentIntro;
  String? _currentRule;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.room.mode;
    _isCommentsClosed = widget.room.isCommentsClosed;
    _freeMic = widget.room.freeMic;
    _currentName = widget.room.roomName;
    _currentIntro = widget.room.roomIntro;
    _currentRule = widget.room.roomRule;
  }

  void _save({
    String? name,
    String? intro,
    String? rule,
    int? mode,
    bool? isCommentsClosed,
    bool? freeMic,
    File? cover,
  }) {
    context.read<RoomManagementBloc>().add(UpdateRoomEvent(
          roomId: widget.room.id,
          name: name,
          intro: intro,
          rule: rule,
          mode: mode,
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
              title:
                  const Text('التقاط صورة', style: TextStyle(color: _textPrimary)),
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

  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Text('عدد المقاعد',
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary)),
            ),
            ...[9, 8, 12, 16, 22, 2].map((mode) => ListTile(
                  title: Text('$mode مقاعد',
                      style: const TextStyle(color: _textPrimary)),
                  trailing: _selectedMode == mode
                      ? const Icon(Icons.check, color: _accent)
                      : null,
                  onTap: () {
                    setState(() => _selectedMode = mode);
                    _save(mode: mode);
                    Navigator.pop(ctx);
                  },
                )),
            SizedBox(height: 8.h),
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
            hintText: 'ادخل كلمة المرور',
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
            onPressed: () => Navigator.pop(ctx),
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RoomManagementBloc, RoomManagementState>(
          listenWhen: (prev, curr) => prev.updateState != curr.updateState,
          listener: (context, state) {
            if (state.updateState == RequestState.loaded) {
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
              context.go('/rooms');
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
          title: const Text('إعدادات الغرفة'),
          centerTitle: true,
          backgroundColor: _bgDark,
          foregroundColor: _textPrimary,
        ),
        body: ListView(
          children: [
            SizedBox(height: 12.h),

            // --- Room Cover ---
            _SettingSection(children: [
              _SettingRow(
                title: 'صورة الغرفة',
                onTap: _pickCover,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 55.r,
                      height: 55.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: _bgDark,
                        border: Border.all(color: _cardBorder, width: 1),
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
                    SizedBox(width: 8.w),
                    const Icon(Icons.chevron_right, color: _textSecondary),
                  ],
                ),
              ),
            ]),

            SizedBox(height: 12.h),

            // --- Room Info ---
            _SettingSection(children: [
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
                      style: TextStyle(
                          color: _textSecondary, fontSize: 14.sp),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.copy, size: 16.r, color: _textSecondary),
                  ],
                ),
              ),
              _divider(),
              _SettingRow(
                title: 'اسم الغرفة',
                onTap: () => _editText(
                  title: 'اسم الغرفة',
                  initialValue: _currentName ?? '',
                  maxLength: 50,
                  onSave: (val) {
                    setState(() => _currentName = val);
                    _save(name: val);
                  },
                ),
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
                    SizedBox(width: 4.w),
                    const Icon(Icons.chevron_right, color: _textSecondary),
                  ],
                ),
              ),
              _divider(),
              _SettingRow(
                title: 'إعلان الغرفة',
                onTap: () => _editText(
                  title: 'إعلان الغرفة',
                  initialValue: _currentIntro ?? '',
                  maxLines: 4,
                  maxLength: 500,
                  onSave: (val) {
                    setState(() => _currentIntro = val);
                    _save(intro: val);
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 150.w,
                      child: Text(
                        _currentIntro ?? 'لا يوجد',
                        style: TextStyle(
                            color: _textSecondary, fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    const Icon(Icons.chevron_right, color: _textSecondary),
                  ],
                ),
              ),
              _divider(),
              _SettingRow(
                title: 'قوانين الغرفة',
                onTap: () => _editText(
                  title: 'قوانين الغرفة',
                  initialValue: _currentRule ?? '',
                  maxLines: 4,
                  maxLength: 500,
                  onSave: (val) {
                    setState(() => _currentRule = val);
                    _save(rule: val);
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 150.w,
                      child: Text(
                        _currentRule ?? 'لا يوجد',
                        style: TextStyle(
                            color: _textSecondary, fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    const Icon(Icons.chevron_right, color: _textSecondary),
                  ],
                ),
              ),
            ]),

            SizedBox(height: 12.h),

            // --- Room Config ---
            _SettingSection(children: [
              _SettingRow(
                title: 'عدد المقاعد',
                onTap: _showModeSelector,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_selectedMode مقاعد',
                      style: TextStyle(
                          color: _textSecondary, fontSize: 14.sp),
                    ),
                    SizedBox(width: 4.w),
                    const Icon(Icons.chevron_right, color: _textSecondary),
                  ],
                ),
              ),
              _divider(),
              _SettingRow(
                title: 'كلمة المرور',
                onTap: widget.room.hasPassword
                    ? () {
                        context.read<RoomManagementBloc>().add(
                              RemovePasswordEvent(roomId: widget.room.id),
                            );
                      }
                    : _showPasswordDialog,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.room.hasPassword ? 'مفعّل' : 'غير مفعّل',
                      style: TextStyle(
                        color: widget.room.hasPassword
                            ? const Color(0xFF2ED9B0)
                            : _textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    const Icon(Icons.chevron_right, color: _textSecondary),
                  ],
                ),
              ),
            ]),

            SizedBox(height: 12.h),

            // --- Toggles ---
            _SettingSection(children: [
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
            ]),

            SizedBox(height: 32.h),

            // --- Delete Room ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: BlocBuilder<RoomManagementBloc, RoomManagementState>(
                buildWhen: (prev, curr) =>
                    prev.deleteState != curr.deleteState,
                builder: (context, state) {
                  final isDeleting =
                      state.deleteState == RequestState.loading;
                  return SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: isDeleting ? null : _confirmDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                          : Text(
                              'حذف الغرفة',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 16, color: _dividerColor);
}

class _SettingSection extends StatelessWidget {
  final List<Widget> children;

  const _SettingSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _cardBorder, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(fontSize: 15.sp, color: _textPrimary)),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
