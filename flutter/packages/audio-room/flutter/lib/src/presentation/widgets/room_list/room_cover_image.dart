import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'room_placeholder.dart';

class RoomCoverImage extends StatelessWidget {
  final String? url;
  const RoomCoverImage({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const RoomPlaceholder(),
        errorWidget: (_, __, ___) => const RoomPlaceholder(),
      );
    }
    return const RoomPlaceholder();
  }
}
