import 'package:flutter/material.dart';

import 'room_strings.dart';

Future<int?> showBanDurationDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => const _BanDurationDialog(),
  );
}

class _BanDurationDialog extends StatelessWidget {
  const _BanDurationDialog();

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
            _DurationTile(
              label: opt.label,
              onTap: () => Navigator.of(context).pop(opt.seconds),
            ),
          _DurationTile(
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

class _DurationTile extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _DurationTile({
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(
        label,
        style: TextStyle(color: color ?? Colors.white, fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}
