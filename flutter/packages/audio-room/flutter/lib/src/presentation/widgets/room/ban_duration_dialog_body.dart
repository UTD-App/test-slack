import 'package:flutter/material.dart';

import 'duration_tile.dart';
import 'room_strings.dart';

class BanDurationDialogBody extends StatelessWidget {
  const BanDurationDialogBody({super.key});

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);
    final options = [
      (label: s.fiveMinutes, seconds: 300),
      (label: s.fifteenMinutes, seconds: 900),
      (label: s.thirtyMinutes, seconds: 1800),
      (label: s.oneHour, seconds: 3600),
      (label: s.twentyFourHours, seconds: 86400),
    ];

    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        s.banUser,
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
            label: s.permanent,
            color: Colors.red,
            onTap: () => Navigator.of(context).pop(-1),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
