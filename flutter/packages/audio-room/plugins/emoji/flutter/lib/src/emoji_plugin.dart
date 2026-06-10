import 'package:audio_room/audio_room.dart';
import 'package:flutter/material.dart';

import 'domain/emoji_model.dart';
import 'presentation/widgets/emoji_picker_sheet.dart';

class EmojiPlugin extends AudioRoomPlugin {
  final ValueChanged<EmojiModel>? onEmojiSelected;

  EmojiPlugin({this.onEmojiSelected});

  @override
  String get id => 'emoji';

  @override
  String get displayName => 'Emojis';

  @override
  Widget? buildControlsWidget(BuildContext context, int roomId) {
    return IconButton(
      icon: const Icon(Icons.emoji_emotions_outlined),
      onPressed: () => EmojiPickerSheet.show(
        context,
        roomId: roomId,
        onEmojiSelected: onEmojiSelected,
      ),
    );
  }

  @override
  Widget? buildOverlayWidget(BuildContext context, int roomId) {
    return null;
  }
}
