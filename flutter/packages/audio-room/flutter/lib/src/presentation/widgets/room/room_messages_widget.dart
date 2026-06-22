import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../audio_room_feature.dart';
import '../../bloc/admin_bloc.dart';
import '../../bloc/blacklist_bloc.dart';
import 'message_input_board.dart';
import 'message_list.dart';
import 'room_strings.dart';
import 'user_profile_sheet.dart';

void openMessageInput(BuildContext context, UTDRoomController controller) {
  Navigator.of(context).push(MessageInputBoard(roomController: controller));
}

enum _MessageTab { all, messages }

class RoomMessagesWidget extends StatefulWidget {
  final UTDRoomController controller;
  final int roomId;
  final bool isOwner;

  const RoomMessagesWidget({
    super.key,
    required this.controller,
    required this.roomId,
    required this.isOwner,
  });

  @override
  State<RoomMessagesWidget> createState() => _RoomMessagesWidgetState();
}

class _RoomMessagesWidgetState extends State<RoomMessagesWidget> {
  _MessageTab _selectedTab = _MessageTab.all;

  bool _isChatMessage(UTDChatMessage m) {
    return m.senderUserId != 'system' &&
        m.userData['type'] != 'join' &&
        !m.text.contains('joinRoom');
  }

  List<UTDChatMessage> _applyTabFilter(List<UTDChatMessage> messages) {
    if (_selectedTab == _MessageTab.all) return messages;
    return messages.where(_isChatMessage).toList();
  }

  @override
  Widget build(BuildContext context) {
    final feature = AudioRoomFeature.instance;
    if (feature == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: feature.pinnedMessage,
          builder: (context, pinned, _) {
            if (pinned == null) return const SizedBox.shrink();
            return _PinnedMessageBanner(
              data: pinned,
              isAdmin: widget.controller.isHostOrAdmin,
              controller: widget.controller,
              roomId: widget.roomId,
              isOwner: widget.isOwner,
              onUnpin: () {
                feature.pinnedMessage.value = null;
                widget.controller.sendRoomMessage({'type': 'unpinMessage'});
              },
            );
          },
        ),
        _buildTabBar(context),
        Expanded(
          child: ValueListenableBuilder<List<UTDChatMessage>>(
            valueListenable: widget.controller.chatController.messages,
            builder: (context, messages, _) {
              if (messages.isEmpty) return const SizedBox.shrink();
              return ValueListenableBuilder<Set<String>>(
                valueListenable: feature.commentBannedUsers,
                builder: (context, bannedIds, _) {
                  var filtered = bannedIds.isEmpty
                      ? messages
                      : messages
                            .where(
                              (m) => !bannedIds.contains(
                                m.userData['senderId']?.toString() ??
                                    m.senderUserId,
                              ),
                            )
                            .toList();
                  filtered = _applyTabFilter(filtered);
                  if (filtered.isEmpty) return const SizedBox.shrink();
                  return MessageList(
                    messages: filtered,
                    controller: widget.controller,
                    roomId: widget.roomId,
                    isOwner: widget.isOwner,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final s = RoomStrings.of(context);
    return Container(
      height: 32.h,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabItem(title: s.allTab, type: _MessageTab.all),
          _buildTabItem(title: s.messagesTab, type: _MessageTab.messages),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required _MessageTab type}) {
    final isSelected = _selectedTab == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
                  bottom: BorderSide(color: Colors.white, width: 2.h),
                )
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PinnedMessageBanner extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isAdmin;
  final UTDRoomController controller;
  final int roomId;
  final bool isOwner;
  final VoidCallback onUnpin;

  const _PinnedMessageBanner({
    required this.data,
    required this.isAdmin,
    required this.controller,
    required this.roomId,
    required this.isOwner,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);
    final senderName = data['senderName']?.toString() ?? '';
    final text = data['text']?.toString() ?? '';
    final avatar = data['senderAvatar']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _openSenderProfile(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          border: Border(
            bottom: BorderSide(
              color: Colors.amber.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.push_pin, color: Colors.amber, size: 16.r),
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 14.r,
              backgroundColor:
                  const Color(0xFF64B5F6).withValues(alpha: 0.3),
              backgroundImage:
                  avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Text(
                      senderName.isNotEmpty
                          ? senderName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    senderName,
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    text,
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isAdmin)
              GestureDetector(
                onTap: () {
                  onUnpin();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.messageUnpinned)),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 18.r,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openSenderProfile(BuildContext context) {
    final senderId = data['senderId']?.toString() ?? '';
    if (senderId.isEmpty) return;
    final seatCtrl = controller.seatController;
    final localId =
        controller.roomManager.localParticipant?.identity ?? '';
    final seatIndex = seatCtrl.getSeatIndexByUserId(senderId);
    final SeatState seat;
    if (seatIndex >= 0) {
      seat = seatCtrl.seats.value[seatIndex];
    } else {
      seat = SeatState(
        index: -1,
        occupantUserId: senderId,
        attributes: {
          'name': data['senderName']?.toString() ?? '',
          'avatar': data['senderAvatar']?.toString() ??
              AudioRoomFeature.instance?.cachedAvatar(senderId) ??
              '',
        },
      );
    }
    showUserProfileSheet(
      context,
      controller: controller,
      seat: seat,
      localUserId: localId,
      isOwner: isOwner,
      roomId: roomId,
      adminBloc: context.read<AdminBloc>(),
      blacklistBloc: context.read<BlacklistBloc>(),
    );
  }
}
