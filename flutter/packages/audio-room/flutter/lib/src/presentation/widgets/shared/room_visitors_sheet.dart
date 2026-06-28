import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_audio_room_kit/utd_audio_room_kit.dart';

import '../../../audio_room_strings.dart';
import '../../bloc/admin/admin_bloc.dart';
import '../../bloc/blacklist/blacklist_bloc.dart';
import '../../bloc/room_management/room_management_bloc.dart';

class RoomVisitorsSheet extends StatelessWidget {
  final int roomId;
  final bool isOwner;
  final bool isAdmin;
  final UTDRoomController? controller;

  const RoomVisitorsSheet({
    super.key,
    required this.roomId,
    this.isOwner = false,
    this.isAdmin = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
                    context.tr(AudioRoomKeys.visitors),
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
                    prev.visitors != curr.visitors ||
                    prev.visitorsState != curr.visitorsState ||
                    prev.hasMoreVisitors != curr.hasMoreVisitors,
                builder: (context, state) {
                  if (state.visitorsState == RequestState.loading &&
                      state.visitors.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.visitors.isEmpty) {
                    return Center(child: Text(context.tr(AudioRoomKeys.noVisitors)));
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 200 &&
                          state.hasMoreVisitors) {
                        context.read<RoomManagementBloc>().add(
                              LoadMoreVisitorsEvent(roomId: roomId),
                            );
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: state.visitors.length +
                          (state.hasMoreVisitors ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.visitors.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CircularProgressIndicator()),
                          );
                        }

                        final visitor = state.visitors[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: visitor.avatar != null
                                ? NetworkImage(visitor.avatar!)
                                : null,
                            child: visitor.avatar == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(visitor.name),
                          trailing: (isOwner || isAdmin)
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'admin':
                                        context.read<AdminBloc>().add(
                                          AddAdminEvent(
                                            roomId: roomId,
                                            userId: visitor.id,
                                          ),
                                        );
                                        controller?.changeRole(
                                          targetIdentity: visitor.id.toString(),
                                          role: 'admin',
                                        );
                                        final promoterData = CacheManager.getUserData();
                                        controller?.sendRoomMessage({
                                          'type': 'roleChange',
                                          'data': {
                                            'user_id': visitor.id.toString(),
                                            'role': 'admin',
                                            'user_name': visitor.name,
                                            'promoter_name': promoterData?['name']?.toString() ?? '',
                                          },
                                        });
                                      case 'kick':
                                        context.read<BlacklistBloc>().add(
                                          KickUserEvent(
                                            roomId: roomId,
                                            userId: visitor.id,
                                          ),
                                        );
                                      case 'ban':
                                        context.read<BlacklistBloc>().add(
                                          BanUserEvent(
                                            roomId: roomId,
                                            userId: visitor.id,
                                          ),
                                        );
                                        controller?.banUser(visitor.id.toString());
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (isOwner)
                                      PopupMenuItem(
                                        value: 'admin',
                                        child: Text(context.tr(AudioRoomKeys.makeAdmin)),
                                      ),
                                    PopupMenuItem(
                                      value: 'kick',
                                      child: Text(context.tr(AudioRoomKeys.kick)),
                                    ),
                                    PopupMenuItem(
                                      value: 'ban',
                                      child: Text(context.tr(AudioRoomKeys.ban)),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
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
