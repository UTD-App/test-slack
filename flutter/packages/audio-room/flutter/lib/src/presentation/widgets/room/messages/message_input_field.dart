import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../../audio_room_feature.dart';
import '../../../../audio_room_strings.dart';

class MessageInputField extends StatefulWidget {
  final UTDRoomController controller;
  final VoidCallback? onSubmit;

  const MessageInputField({super.key, required this.controller, this.onSubmit});

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final _textController = TextEditingController();
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
  }

  Map<String, dynamic> _buildUserData() {
    final userData = CacheManager.getUserData();
    final profile = userData?['profile'];
    debugPrint('[MSG] userData keys: ${userData?.keys.toList()}');
    debugPrint('[MSG] profile: $profile');
    debugPrint('[MSG] profile type: ${profile.runtimeType}');
    final avatar = userData?['avatar']?.toString() ??
        userData?['image']?.toString() ??
        (profile is Map ? profile['image']?.toString() : null) ??
        '';
    return {
      'senderId': userData?['id']?.toString() ?? '',
      'senderName': userData?['name']?.toString() ?? '',
      'senderAvatar': avatar,
      'type': 'message',
    };
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final userData = _buildUserData();
    final senderId = userData['senderId']?.toString() ?? '';
    final avatar = userData['senderAvatar']?.toString() ?? '';
    if (senderId.isNotEmpty) {
      AudioRoomFeature.instance?.cacheAvatar(senderId, avatar);
    }

    widget.controller.chatController.sendMessage(text, userData: userData);
    _textController.clear();
    setState(() => _isEmpty = true);
    widget.onSubmit?.call();
  }

  void _onTextChanged(String value) {
    setState(() => _isEmpty = value.trim().isEmpty);
    if (value.endsWith('@')) {
      _showMentionSheet();
    }
  }

  void _showMentionSheet() {
    final participants = widget.controller.participants;
    final localId =
        widget.controller.roomManager.localParticipant?.identity ?? '';

    final mentionedNames = RegExp(r'@([\w_]+)')
        .allMatches(_textController.text)
        .map((m) => m.group(1)?.toLowerCase())
        .whereType<String>()
        .toSet();

    final available = participants.where((p) {
      if (p.id == localId) return false;
      final normalized = p.name.replaceAll(' ', '_').toLowerCase();
      return !mentionedNames.contains(normalized);
    }).toList();

    if (available.isEmpty) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.55,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alternate_email_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        isAr ? 'اذكر شخص' : 'Mention someone',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Divider(height: 1, color: Colors.grey.shade200),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final user = available[index];
                      return InkWell(
                        onTap: () {
                          final text = _textController.text;
                          final name = user.name.replaceAll(' ', '_');
                          final newText = text.replaceRange(
                            text.lastIndexOf('@'),
                            text.length,
                            '@$name ',
                          );
                          _textController.text = newText;
                          _textController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: _textController.text.length),
                          );
                          setState(() => _isEmpty = newText.trim().isEmpty);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15.sp,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'ID: ${user.id}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey.shade400,
                                size: 20.r,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      color: const Color(0xff222222).withValues(alpha: 0.8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: 42.h, maxHeight: 120.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: null,
                  inputFormatters: [LengthLimitingTextInputFormatter(199)],
                  style: TextStyle(color: Colors.black, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: context.tr(AudioRoomKeys.sendMessageHint),
                    hintStyle: TextStyle(
                      color: Colors.black.withValues(alpha: 0.4),
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onChanged: _onTextChanged,
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: _isEmpty ? null : _send,
              child: Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isEmpty
                      ? Colors.grey.withValues(alpha: 0.3)
                      : Theme.of(context).primaryColor,
                ),
                child: Icon(Icons.send, color: Colors.white, size: 20.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
