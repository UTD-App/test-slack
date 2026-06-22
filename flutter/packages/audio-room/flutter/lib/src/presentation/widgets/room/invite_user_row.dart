import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'room_strings.dart';

class InviteUserRow extends StatelessWidget {
  final UTDParticipant user;
  final bool invited;
  final VoidCallback onInvite;

  const InviteUserRow({
    super.key,
    required this.user,
    required this.invited,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);
    final avatar = user.attributes['avatar'];

    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Colors.white.withValues(alpha: 0.06),
      leading: ClipOval(
        child: avatar != null && avatar.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatar,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _defaultAvatar(),
              )
            : _defaultAvatar(),
      ),
      title: Text(
        user.name.isNotEmpty ? user.name : '${s.user} ${user.id}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 75,
        height: 30,
        child: ElevatedButton(
          onPressed: invited ? null : onInvite,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                invited ? Colors.grey.shade700 : const Color(0xFF4CAF50),
            disabledBackgroundColor: Colors.grey.shade700,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            invited ? s.sent : s.invite,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade600,
      ),
      child: const Icon(Icons.person, color: Colors.white70, size: 20),
    );
  }
}
