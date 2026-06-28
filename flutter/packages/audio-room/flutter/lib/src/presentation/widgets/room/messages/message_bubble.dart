import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../../audio_room_feature.dart';
import '../../../../audio_room_strings.dart';
import '../../../bloc/admin/admin_bloc.dart';
import '../../../bloc/blacklist/blacklist_bloc.dart';
import '../profile/user_profile_sheet.dart';
import 'message_actions_sheet.dart';

class MessageBubble extends StatefulWidget {
  final UTDChatMessage message;
  final UTDRoomController controller;
  final int roomId;
  final bool isOwner;
  final ValueNotifier<int> timeTick;

  const MessageBubble({
    super.key,
    required this.message,
    required this.controller,
    required this.roomId,
    required this.isOwner,
    required this.timeTick,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final List<TapGestureRecognizer> _recognizers = [];

  UTDChatMessage get message => widget.message;

  bool get _isSystem => message.senderUserId == 'system';

  bool get _isJoinMessage =>
      message.text.contains('joinRoom') || message.userData['type'] == 'join';

  bool get _isPlainRtm => message.senderName.isEmpty && _avatarUrl == null;

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSystem) return _buildSystemMessage();
    if (_isJoinMessage) return _buildJoinMessage(context);
    if (_isPlainRtm) return _buildPlainMessage(context);
    return _buildUserMessage(context);
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildJoinMessage(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.r),
          color: const Color(0xFFD9D9D9).withValues(alpha: 0.25),
        ),
        child: Text(
          context.trArgs(AudioRoomKeys.userJoined, {'name': message.senderName}),
          style: TextStyle(color: Colors.white, fontSize: 13.sp),
        ),
      ),
    );
  }

  String? get _avatarUrl {
    final senderId =
        message.userData['senderId']?.toString() ?? message.senderUserId;
    final feature = AudioRoomFeature.instance;

    final url = message.userData['senderAvatar']?.toString();
    if (url != null && url.isNotEmpty) {
      feature?.cacheAvatar(senderId, url);
      return url;
    }

    final seatCtrl = widget.controller.seatController;
    final idx = seatCtrl.getSeatIndexByUserId(senderId);
    if (idx >= 0) {
      final av = seatCtrl.seats.value[idx].attributes['avatar'];
      if (av != null && av.isNotEmpty) {
        feature?.cacheAvatar(senderId, av);
        return av;
      }
    }

    return feature?.cachedAvatar(senderId);
  }

  static String _relativeTime(DateTime timestamp, BuildContext context) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return context.tr(AudioRoomKeys.justNow);
    if (diff.inMinutes < 60) return context.trArgs(AudioRoomKeys.minutesAgo, {'n': '${diff.inMinutes}'});
    if (diff.inHours < 24) return context.trArgs(AudioRoomKeys.hoursAgo, {'n': '${diff.inHours}'});
    return context.trArgs(AudioRoomKeys.daysAgo, {'n': '${diff.inDays}'});
  }

  Widget _buildPlainMessage(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
      child: Text.rich(
        TextSpan(children: _buildStyledSpans(context, message.text)),
      ),
    );
  }

  bool get _isPinned {
    final pinned = AudioRoomFeature.instance?.pinnedMessage.value;
    if (pinned == null) return false;
    return pinned['text'] == message.text &&
        pinned['senderName'] == message.senderName &&
        pinned['timestamp'] == message.timestamp.millisecondsSinceEpoch;
  }

  Widget _buildUserMessage(BuildContext context) {
    _disposeRecognizers();
    final avatar = _avatarUrl;
    final initial = message.senderName.isNotEmpty
        ? message.senderName[0].toUpperCase()
        : '?';

    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: AudioRoomFeature.instance!.pinnedMessage,
      builder: (context, _, __) {
        final pinned = _isPinned;
        return GestureDetector(
          onLongPress: widget.controller.isHostOrAdmin
              ? () => _onPinMessage(context)
              : null,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: pinned
                    ? Colors.amber.withValues(alpha: 0.12)
                    : const Color(0xFFD9D9D9).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8.r),
                border: pinned
                    ? Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pinned)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Row(
                        children: [
                          Icon(Icons.push_pin,
                              color: Colors.amber, size: 12.r),
                          SizedBox(width: 4.w),
                          Text(
                            context.tr(AudioRoomKeys.pinMessage),
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _onSenderTap(context),
                        child: CircleAvatar(
                          radius: 16.r,
                          backgroundColor: const Color(
                            0xFF64B5F6,
                          ).withValues(alpha: 0.3),
                          backgroundImage:
                              avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Text(
                                  initial,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () => _onSenderTap(context),
                                    child: Text(
                                      message.senderName,
                                      style: TextStyle(
                                        color: const Color(0xFF64B5F6),
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                ValueListenableBuilder<int>(
                                  valueListenable: widget.timeTick,
                                  builder: (_, __, ___) => Text(
                                    _relativeTime(message.timestamp, context),
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text.rich(
                              TextSpan(
                                children:
                                    _buildStyledSpans(context, message.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPinMessage(BuildContext context) {
    showMessageActionsSheet(
      context,
      message: message,
      controller: widget.controller,
      isPinned: _isPinned,
      avatarUrl: _avatarUrl,
      roomId: widget.roomId,
    );
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  static final RegExp _mentionRegex = RegExp(r'@[\w_]+');

  List<TextSpan> _buildStyledSpans(BuildContext context, String text) {
    final spans = <TextSpan>[];
    text.splitMapJoin(
      _mentionRegex,
      onMatch: (match) {
        final mentionText = match[0]!;
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _onMentionTap(context, mentionText);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: mentionText,
            recognizer: recognizer,
            style: TextStyle(
              color: const Color(0xFF7C4DFF),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        return '';
      },
      onNonMatch: (nonMatch) {
        spans.add(
          TextSpan(
            text: nonMatch,
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
        );
        return '';
      },
    );
    return spans;
  }

  void _onSenderTap(BuildContext context) {
    final senderId =
        message.userData['senderId']?.toString() ?? message.senderUserId;
    final seatCtrl = widget.controller.seatController;
    final localId =
        widget.controller.roomManager.localParticipant?.identity ?? '';

    final seatIndex = seatCtrl.getSeatIndexByUserId(senderId);
    final SeatState seat;
    if (seatIndex >= 0) {
      seat = seatCtrl.seats.value[seatIndex];
    } else {
      seat = SeatState(
        index: -1,
        occupantUserId: senderId,
        attributes: {
          'name': message.senderName,
          'avatar': _avatarUrl ?? '',
        },
      );
    }

    showUserProfileSheet(
      context,
      controller: widget.controller,
      seat: seat,
      localUserId: localId,
      isOwner: widget.isOwner,
      roomId: widget.roomId,
      adminBloc: context.read<AdminBloc>(),
      blacklistBloc: context.read<BlacklistBloc>(),
    );
  }

  void _onMentionTap(BuildContext context, String mentionText) {
    final username = mentionText.substring(1).toLowerCase();
    final participants = widget.controller.participants;
    final seatCtrl = widget.controller.seatController;
    final localId =
        widget.controller.roomManager.localParticipant?.identity ?? '';

    UTDParticipant? participant;
    for (final p in participants) {
      if (p.name.replaceAll(' ', '_').toLowerCase() == username) {
        participant = p;
        break;
      }
    }
    if (participant == null) return;

    final seatIndex = seatCtrl.getSeatIndexByUserId(participant.id);
    final SeatState seat;
    if (seatIndex >= 0) {
      seat = seatCtrl.seats.value[seatIndex];
    } else {
      seat = SeatState(
        index: -1,
        occupantUserId: participant.id,
        attributes: {'name': participant.name},
      );
    }

    showUserProfileSheet(
      context,
      controller: widget.controller,
      seat: seat,
      localUserId: localId,
      isOwner: widget.isOwner,
      roomId: widget.roomId,
      adminBloc: context.read<AdminBloc>(),
      blacklistBloc: context.read<BlacklistBloc>(),
    );
  }
}
