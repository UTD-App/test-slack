import 'package:flutter/material.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import 'room_strings.dart';

Future<bool> showSpeakerInvitationDialog(
  BuildContext context,
  Map<String, dynamic> data, {
  UTDRoomController? controller,
}) async {
  final s = RoomStrings.of(context);
  final seatIndex = data['seat_index'] as int? ?? 0;
  final inviterId = data['inviter_identity']?.toString();

  String inviterName = data['inviter_name']?.toString() ?? s.host;
  String? inviterAvatar = data['inviter_avatar']?.toString();

  if (inviterId != null && controller != null) {
    for (final p in controller.participants) {
      if (p.id == inviterId) {
        if (p.name.isNotEmpty) inviterName = p.name;
        final av = p.attributes['avatar'];
        if (av != null && av.isNotEmpty) inviterAvatar = av;
        break;
      }
    }
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _InviterAvatar(url: inviterAvatar),
          const SizedBox(height: 12),
          Text(
            inviterName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.invitationToMic(seatIndex),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    s.decline,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    s.accept,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  return result ?? false;
}

class _InviterAvatar extends StatelessWidget {
  final String? url;

  const _InviterAvatar({this.url});

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
