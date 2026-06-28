import 'package:flutter/material.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../audio_room_strings.dart';
import 'duration_tile.dart';

class BanDurationDialogBody extends StatelessWidget {
  const BanDurationDialogBody({super.key});

  @override
  Widget build(BuildContext context) {
    final options = [
      (label: context.tr(AudioRoomKeys.fiveMinutes), seconds: 300),
      (label: context.tr(AudioRoomKeys.fifteenMinutes), seconds: 900),
      (label: context.tr(AudioRoomKeys.thirtyMinutes), seconds: 1800),
      (label: context.tr(AudioRoomKeys.oneHour), seconds: 3600),
      (label: context.tr(AudioRoomKeys.twentyFourHours), seconds: 86400),
    ];

    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        context.tr(AudioRoomKeys.banUser),
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final opt in options)
            DurationTile(
              label: opt.label,
              onTap: () => Navigator.of(context).pop(opt.seconds),
            ),
          DurationTile(
            label: context.tr(AudioRoomKeys.permanent),
            color: Colors.red,
            onTap: () => Navigator.of(context).pop(-1),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr(AudioRoomKeys.cancel), style: const TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
