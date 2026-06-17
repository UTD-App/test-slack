import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../bloc/admin_bloc.dart';
import 'room/room_strings.dart';

class RoomAdminSheet extends StatelessWidget {
  final int roomId;

  const RoomAdminSheet({super.key, required this.roomId});

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
                    s.admins,
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
              child: BlocBuilder<AdminBloc, AdminState>(
                buildWhen: (prev, curr) =>
                    prev.admins != curr.admins ||
                    prev.adminsState != curr.adminsState,
                builder: (context, state) {
                  if (state.adminsState == RequestState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.admins.isEmpty) {
                    return Center(child: Text(s.noAdmins));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: state.admins.length,
                    itemBuilder: (context, index) {
                      final admin = state.admins[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: admin.avatar != null
                              ? NetworkImage(admin.avatar!)
                              : null,
                          child: admin.avatar == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(admin.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () {
                            context.read<AdminBloc>().add(
                                  RemoveAdminEvent(
                                    roomId: roomId,
                                    userId: admin.id,
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
