import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ListCardOwnerAvatar extends StatelessWidget {
  final String? url;
  final double size;
  const ListCardOwnerAvatar({super.key, this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _avatarFallback(size),
        ),
      );
    }
    return _avatarFallback(size);
  }

  static Widget _avatarFallback(double size) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade500,
      child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
    );
  }
}
