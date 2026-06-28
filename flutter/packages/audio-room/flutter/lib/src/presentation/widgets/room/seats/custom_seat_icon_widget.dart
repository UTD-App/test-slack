import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const _presetIcons = <String, IconData>{
  'star': Icons.star_rounded,
  'headphones': Icons.headphones_rounded,
  'music_note': Icons.music_note_rounded,
  'person': Icons.person_rounded,
  'favorite': Icons.favorite_rounded,
  'diamond': Icons.diamond_rounded,
};

class CustomSeatIconWidget extends StatelessWidget {
  final int index;
  final double size;
  final String iconValue;

  const CustomSeatIconWidget({
    super.key,
    required this.index,
    required this.size,
    required this.iconValue,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: iconValue.startsWith('preset:')
              ? Icon(
                  _presetIcons[iconValue.substring(7)] ??
                      Icons.mic_none_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: iconSize * 0.45,
                )
              : ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: iconValue,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Icon(
                      Icons.mic_none_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: iconSize * 0.45,
                    ),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.mic_none_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: iconSize * 0.45,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 2),
        Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
