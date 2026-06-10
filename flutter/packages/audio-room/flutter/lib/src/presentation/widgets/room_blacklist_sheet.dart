import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../bloc/room_management_bloc.dart';
import 'room/room_strings.dart';

class RoomBlacklistSheet extends StatelessWidget {
  final int roomId;

  const RoomBlacklistSheet({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final s = RoomStrings.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Text(
                    s.blacklist,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<RoomManagementBloc, RoomManagementState>(
                buildWhen: (prev, curr) =>
                    prev.blacklist != curr.blacklist ||
                    prev.blacklistState != curr.blacklistState,
                builder: (context, state) {
                  if (state.blacklistState == RequestState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.blacklist.isEmpty) {
                    return Center(child: Text(s.noBlacklist));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: state.blacklist.length,
                    itemBuilder: (context, index) {
                      final entry = state.blacklist[index];
                      final userName =
                          entry['user_name'] as String? ?? s.unknown;
                      final userId = (entry['user_id'] as num?)?.toInt() ?? 0;
                      final reason = entry['reason'] as String?;
                      final expiresAt = entry['expires_at'] as String?;

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.block),
                        ),
                        title: Text(userName),
                        subtitle: Text(
                          reason ?? (expiresAt != null
                              ? s.expiresAt(expiresAt)
                              : s.permanentBan),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.green),
                          onPressed: () {
                            context.read<RoomManagementBloc>().add(
                                  UnbanUserEvent(
                                    roomId: roomId,
                                    userId: userId,
                                  ),
                                );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
