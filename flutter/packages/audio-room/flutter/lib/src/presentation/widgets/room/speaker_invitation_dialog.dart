import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'room_strings.dart';

Future<bool> showSpeakerInvitationDialog(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  final s = RoomStrings.of(context);
  final seatIndex = data['seat_index'] as int? ?? 0;
  final inviterName = data['inviter_name']?.toString() ?? s.host;
  final inviterAvatar = data['inviter_avatar']?.toString();

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
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundColor: Colors.grey.shade700,
        child: const Icon(Icons.person, size: 36, color: Colors.white70),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: 36,
          backgroundColor: Colors.grey.shade700,
          child: const Icon(Icons.person, size: 36, color: Colors.white70),
        ),
      ),
    );
  }
}
