import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SeatAvatarImage extends StatelessWidget {
  final String url;
  final double size;

  const SeatAvatarImage({super.key, required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade700,
        ),
        child: Icon(
          Icons.person,
          color: Colors.white.withValues(alpha: 0.7),
          size: size * 0.5,
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade700,
          ),
          child: Icon(
            Icons.person,
            color: Colors.white.withValues(alpha: 0.7),
            size: size * 0.5,
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade700,
          ),
          child: Icon(
            Icons.person,
            color: Colors.white.withValues(alpha: 0.7),
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
