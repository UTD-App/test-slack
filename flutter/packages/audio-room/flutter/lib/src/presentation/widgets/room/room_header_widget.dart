import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../domain/room_model.dart';
import 'room_assets.dart';
import 'room_strings.dart';

class RoomHeaderWidget extends StatelessWidget {
  final RoomModel room;
  final UTDRoomController controller;
  final VoidCallback onExit;
  final VoidCallback? onMinimize;
  final VoidCallback? onAdminsTap;
  final VoidCallback? onSettingsTap;

  const RoomHeaderWidget({
    super.key,
    required this.room,
    required this.controller,
    required this.onExit,
    this.onMinimize,
    this.onAdminsTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onSettingsTap,
                  child: _RoomInfo(room: room),
                ),
                const Spacer(),
                _VisitorCount(
                  controller: controller,
                  onTap: () =>
                      UTDMemberListSheet.show(context, controller: controller),
                ),
                const SizedBox(width: 4),
                if (room.isOwner == true || room.isAdmin == true)
                  _AdminMenu(
                    onAdminsTap: onAdminsTap,
                    onBlacklistTap: () => UTDBanManagementSheet.show(
                      context,
                      controller: controller,
                    ),
                  ),
                _ExitButton(onTap: () => _confirmExit(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    final s = RoomStrings.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (onMinimize != null)
              _ExitOption(
                icon: Icons.picture_in_picture_alt,
                label: s.keep,
                color: Colors.blue,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onMinimize!();
                },
              ),
            _ExitOption(
              icon: Icons.exit_to_app,
              label: s.leave,
              color: Colors.red,
              onTap: () {
                Navigator.of(ctx).pop();
                onExit();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomInfo extends StatelessWidget {
  final RoomModel room;

  const _RoomInfo({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OwnerAvatar(url: room.roomCover ?? room.ownerAvatar, size: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room.roomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ID: ${room.numId}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  final String? url;
  final double size;

  const _OwnerAvatar({this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade600,
        child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey.shade600,
          child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
        ),
      ),
    );
  }
}

class _VisitorCount extends StatelessWidget {
  final UTDRoomController controller;
  final VoidCallback? onTap;

  const _VisitorCount({required this.controller, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UTDParticipant>>(
      stream: controller.participantsStream,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? controller.participants.length;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminMenu extends StatelessWidget {
  final VoidCallback? onAdminsTap;
  final VoidCallback? onBlacklistTap;

  const _AdminMenu({this.onAdminsTap, this.onBlacklistTap});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
      color: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'admins':
            onAdminsTap?.call();
          case 'blacklist':
            onBlacklistTap?.call();
        }
      },
      itemBuilder: (ctx) {
        final s = RoomStrings.of(ctx);
        return [
          PopupMenuItem(
            value: 'admins',
            child: Text(s.admins, style: const TextStyle(color: Colors.white)),
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
  }
}

class _ExitOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExitOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ExitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: 0.2),
        ),
        child: Image.asset(RoomAssets.exitRoom, color: Colors.red),
      ),
    );
  }
}
