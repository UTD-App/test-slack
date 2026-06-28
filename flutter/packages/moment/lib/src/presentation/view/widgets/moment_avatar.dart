import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:utd_app/shared/media/app_cache_manager.dart';

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

  /// Optional tap handler (e.g. open the user's profile).
  final VoidCallback? onTap;

  const MomentAvatar({
    super.key,
    required this.image,
    required this.name,
    this.radius = 20,
    this.onTap,
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

    final avatar = url.isEmpty
        ? CircleAvatar(radius: radius, backgroundColor: bg, child: initialsWidget)
        : CircleAvatar(
            radius: radius,
            backgroundColor: bg,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                cacheManager: AppCacheManager.instance.manager,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(child: initialsWidget),
                errorWidget: (_, __, ___) => Center(child: initialsWidget),
              ),
            ),
          );

    if (onTap == null) return avatar;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: avatar);
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
