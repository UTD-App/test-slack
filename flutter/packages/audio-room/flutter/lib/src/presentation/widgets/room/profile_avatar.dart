import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? url;

  const ProfileAvatar({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey.shade700,
        child: const Icon(Icons.person, size: 40, color: Colors.white70),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade700,
          child: const Icon(Icons.person, size: 40, color: Colors.white70),
        ),
      ),
    );
  }
}
