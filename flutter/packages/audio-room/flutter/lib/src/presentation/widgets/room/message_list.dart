import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'message_bubble.dart';

class MessageList extends StatefulWidget {
  final List<UTDChatMessage> messages;
  final UTDRoomController controller;
  final int roomId;
  final bool isOwner;

  const MessageList({
    super.key,
    required this.messages,
    required this.controller,
    required this.roomId,
    required this.isOwner,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _timeTick = ValueNotifier(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _timeTick.value++,
    );
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeTick.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(
          message: widget.messages[index],
          controller: widget.controller,
          roomId: widget.roomId,
          isOwner: widget.isOwner,
          timeTick: _timeTick,
        );
      },
    );
  }
}
