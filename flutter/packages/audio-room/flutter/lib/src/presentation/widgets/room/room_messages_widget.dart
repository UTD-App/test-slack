import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'room_strings.dart';

class RoomMessagesWidget extends StatelessWidget {
  final UTDRoomController controller;

  const RoomMessagesWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<UTDChatMessage>>(
      valueListenable: controller.chatController.messages,
      builder: (context, messages, _) {
        return Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const SizedBox.shrink()
                  : _MessageList(messages: messages),
            ),
            _MessageInput(controller: controller),
          ],
        );
      },
    );
  }
}

class _MessageList extends StatefulWidget {
  final List<UTDChatMessage> messages;

  const _MessageList({required this.messages});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(_MessageList oldWidget) {
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        return _MessageBubble(message: widget.messages[index]);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final UTDChatMessage message;

  const _MessageBubble({required this.message});

  bool get _isSystem => message.senderUserId == 'system';

  @override
  Widget build(BuildContext context) {
    if (_isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${message.senderName}  ',
                style: const TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final UTDRoomController controller;

  const _MessageInput({required this.controller});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _textController = TextEditingController();
  bool _isEmpty = true;

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.controller.chatController.sendMessage(text);
    _textController.clear();
    setState(() => _isEmpty = true);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(19),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: RoomStrings.of(context).sendMessageHint,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onChanged: (v) => setState(() => _isEmpty = v.trim().isEmpty),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isEmpty ? null : _send,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isEmpty
                    ? Colors.white.withValues(alpha: 0.1)
                    : Theme.of(context).primaryColor,
              ),
              child: Icon(
                Icons.send,
                color: _isEmpty ? Colors.white38 : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
