import 'package:flutter/material.dart';

import '../../utils/media.dart';

/// User avatar that works offline.
///
/// When the user has a real picture it loads it (relative storage paths are
/// resolved against the app domain); otherwise — or if the image fails to load —
/// it renders a colored circle with the user's initials. No external avatar
/// service is used, so it always shows something even with no network.
class MomentAvatar extends StatelessWidget {
  final String image;
  final String name;
  final double radius;

  const MomentAvatar({
    super.key,
    required this.image,
    required this.name,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(image);
    final bg = _colorFor(name);
    final initialsWidget = Text(
      _initials(name),
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * 0.8,
        fontWeight: FontWeight.w600,
      ),
    );

    if (url.isEmpty) {
      return CircleAvatar(radius: radius, backgroundColor: bg, child: initialsWidget);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(child: initialsWidget),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : Center(child: initialsWidget),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
  }

  /// Deterministic background color derived from the name (stable per user).
  static Color _colorFor(String name) {
    const palette = [
      Color(0xFF4F46E5), Color(0xFF0EA5E9), Color(0xFF10B981),
      Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFFEC4899),
      Color(0xFF8B5CF6), Color(0xFF14B8A6),
    ];
    if (name.isEmpty) return palette.first;
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }
}
