import 'dart:io';

import 'package:flutter/material.dart';

import '../room/room_theme.dart';

class FileIconPreview extends StatelessWidget {
  final File file;
  final double size;

  const FileIconPreview({super.key, required this.file, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: RoomTheme.textSecondary.withValues(alpha: 0.3)),
        image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
      ),
    );
  }
}
