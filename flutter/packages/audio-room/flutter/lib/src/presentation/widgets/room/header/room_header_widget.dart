import 'package:flutter/material.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../../audio_room_strings.dart';
import '../../../../domain/room_model.dart';
import '../admin/admin_menu.dart';
import 'exit_button.dart';
import '../shared/exit_option.dart';
import 'favorite_button.dart';
import 'room_info.dart';
import 'visitor_count.dart';

class RoomHeaderWidget extends StatelessWidget {
  final RoomModel room;
  final UTDRoomController controller;
  final VoidCallback onExit;
  final VoidCallback? onMinimize;
  final VoidCallback? onAdminsTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onModeTap;
  final ValueChanged<bool>? onLockCommentsToggled;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const RoomHeaderWidget({
    super.key,
    required this.room,
    required this.controller,
    required this.onExit,
    this.onMinimize,
    this.onAdminsTap,
    this.onSettingsTap,
    this.onModeTap,
    this.onLockCommentsToggled,
    this.onFavoriteTap,
    this.isFavorite = false,
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
                  child: RoomInfo(room: room),
                ),
                const Spacer(),
                VisitorCount(
                  controller: controller,
                  onTap: () =>
                      UTDMemberListSheet.show(context, controller: controller),
                ),
                const SizedBox(width: 4),
                if (room.isOwner != true)
                  FavoriteButton(isFavorite: isFavorite, onTap: onFavoriteTap),
                if (room.isOwner == true || room.isAdmin == true)
                  AdminMenu(
                    controller: controller,
                    onAdminsTap: onAdminsTap,
                    onBlacklistTap: () => UTDBanManagementSheet.show(
                      context,
                      controller: controller,
                    ),
                    onLockCommentsToggled: onLockCommentsToggled,
                  ),
                ExitButton(onTap: () => _confirmExit(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (onMinimize != null)
              ExitOption(
                icon: Icons.picture_in_picture_alt,
                label: context.tr(AudioRoomKeys.keep),
                color: Colors.blue,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onMinimize!();
                },
              ),
            ExitOption(
              icon: Icons.exit_to_app,
              label: context.tr(AudioRoomKeys.leave),
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
