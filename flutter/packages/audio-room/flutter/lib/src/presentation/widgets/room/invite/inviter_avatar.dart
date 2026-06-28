import 'package:flutter/material.dart';

class InviterAvatar extends StatelessWidget {
  final String? url;

  const InviterAvatar({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.isNotEmpty;
    return CircleAvatar(
      radius: 36,
      backgroundColor: Colors.grey.shade700,
      backgroundImage: hasImage ? NetworkImage(url!) : null,
      child: hasImage
          ? null
          : const Icon(Icons.person, size: 36, color: Colors.white70),
    );
  }
}
