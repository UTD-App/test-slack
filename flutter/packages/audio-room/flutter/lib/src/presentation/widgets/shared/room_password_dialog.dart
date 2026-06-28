import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoomPasswordDialog extends StatefulWidget {
  const RoomPasswordDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const RoomPasswordDialog(),
    );
  }

  @override
  State<RoomPasswordDialog> createState() => _RoomPasswordDialogState();
}

class _RoomPasswordDialogState extends State<RoomPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('audio_room.enter_password'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'audio_room.password_hint',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) Navigator.of(context).pop(value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('audio_room.cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final password = _controller.text.trim();
            if (password.isNotEmpty) Navigator.of(context).pop(password);
          },
          child: const Text('audio_room.enter'),
        ),
      ],
    );
  }
}
