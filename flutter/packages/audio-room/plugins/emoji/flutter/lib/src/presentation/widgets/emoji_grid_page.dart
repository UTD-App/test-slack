import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/emoji_model.dart';

class EmojiGridPage extends StatelessWidget {
  final List<EmojiModel> emojis;
  final ValueChanged<EmojiModel> onEmojiSelected;

  const EmojiGridPage({
    super.key,
    required this.emojis,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return GestureDetector(
          onTap: () => onEmojiSelected(emoji),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: emoji.emoji.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: emoji.emoji,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.emoji_emotions, size: 28),
                  )
                : const Icon(Icons.emoji_emotions, size: 28),
          ),
        );
      },
    );
  }
}
