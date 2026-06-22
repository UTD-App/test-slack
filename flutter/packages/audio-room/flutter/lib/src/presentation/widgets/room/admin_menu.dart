import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'room_strings.dart';

class AdminMenu extends StatelessWidget {
  final UTDRoomController controller;
  final VoidCallback? onAdminsTap;
  final VoidCallback? onBlacklistTap;
  final ValueChanged<bool>? onLockCommentsToggled;

  const AdminMenu({
    super.key,
    required this.controller,
    this.onAdminsTap,
    this.onBlacklistTap,
    this.onLockCommentsToggled,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.commentsLocked,
      builder: (context, isLocked, _) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          color: const Color(0xFF2A2A3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            switch (value) {
              case 'admins':
                onAdminsTap?.call();
              case 'blacklist':
                onBlacklistTap?.call();
              case 'lockComments':
                final newState = !isLocked;
                onLockCommentsToggled?.call(newState);
                controller.setCommentsLocked(newState);
            }
          },
          itemBuilder: (ctx) {
            final s = RoomStrings.of(ctx);
            return [
              PopupMenuItem(
                value: 'lockComments',
                child: Row(
                  children: [
                    Icon(
                      isLocked
                          ? Icons.chat_bubble_outline
                          : Icons.comments_disabled_outlined,
                      color: isLocked ? const Color(0xFF32e5ac) : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isLocked ? s.unlockComments : s.lockComments,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'admins',
                child: Text(
                  s.admins,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: 'blacklist',
                child: Text(
                  s.blacklist,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ];
          },
        );
      },
    );
  }
}
