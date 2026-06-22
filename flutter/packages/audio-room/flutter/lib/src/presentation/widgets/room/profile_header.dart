import 'package:flutter/material.dart';

import 'profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final String? avatarUrl;
  final String userName;
  final String userId;
  final String? role;

  const ProfileHeader({
    super.key,
    this.avatarUrl,
    required this.userName,
    required this.userId,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        ProfileAvatar(url: avatarUrl),
        const SizedBox(height: 12),
        Text(
          userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ID: $userId',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        if (role != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                role!,
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
