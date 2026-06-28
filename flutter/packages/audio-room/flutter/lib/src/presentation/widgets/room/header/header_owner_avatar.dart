import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HeaderOwnerAvatar extends StatelessWidget {
  final String? url;
  final double size;

  const HeaderOwnerAvatar({super.key, this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade600,
        child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.grey.shade600,
          child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
        ),
      ),
    );
  }
}
