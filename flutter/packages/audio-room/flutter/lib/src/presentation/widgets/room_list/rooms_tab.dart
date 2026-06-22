import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../../audio_room_strings.dart';
import '../../../domain/room_model.dart';
import '../../bloc/room_list_bloc.dart';
import '../audio_room_app_overlay.dart';
import '../room_card.dart';
import '../room_list_card.dart';
import 'enter_room_password_sheet.dart';
import 'room_categories_bar.dart';
import 'room_empty_state.dart';
import 'room_error_state.dart';

class RoomsTab extends StatelessWidget {
  const RoomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const RoomCategoriesBar(),
        SizedBox(height: 4.h),
        const Expanded(child: RoomGrid()),
      ],
    );
  }
}

class RoomGrid extends StatelessWidget {
  const RoomGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = CacheManager.getUserData()?['id'] as int?;

    return BlocBuilder<RoomListBloc, RoomListState>(
      builder: (context, state) {
        switch (state.roomsState) {
          case RequestState.loading:
            return const Center(child: CircularProgressIndicator());
          case RequestState.error:
            return RoomErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<RoomListBloc>().add(const LoadRoomsEvent()),
            );
          case RequestState.empty:
            return RoomEmptyState(
              icon: Icons.meeting_room_outlined,
              message: context.tr(AudioRoomKeys.empty),
            );
          case RequestState.loaded:
            return RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<RoomListBloc>();
                bloc.add(const LoadRoomsEvent());
                bloc.add(const LoadCategoriesEvent());
                bloc.add(const LoadMyRoomEvent());
                bloc.add(const LoadFavoritesEvent());
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification &&
                      notification.metrics.extentAfter < 200 &&
                      state.hasMore) {
                    context.read<RoomListBloc>().add(
                      const LoadMoreRoomsEvent(),
                    );
                  }
                  return false;
                },
                child: state.isGridView
                    ? _buildGrid(context, state.rooms, myId)
                    : _buildList(context, state.rooms, myId),
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<RoomModel> rooms, int? myId) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(14.r, 4.r, 14.r, 14.r),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.82,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) =>
          _roomItem(context, rooms[index], myId, grid: true),
    );
  }

  Widget _buildList(BuildContext context, List<RoomModel> rooms, int? myId) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(14.r, 4.r, 14.r, 14.r),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: _roomItem(context, rooms[index], myId, grid: false),
        );
      },
    );
  }

  Widget _roomItem(
    BuildContext context,
    RoomModel room,
    int? myId, {
    required bool grid,
  }) {
    final isOwner = myId != null && myId == room.ownerId;
    final card = grid
        ? RoomCard(
            room: room,
            showFavorite: !isOwner,
            onFavoriteTap: () => context.read<RoomListBloc>().add(
              ToggleFavoriteEvent(roomId: room.id),
            ),
            onTap: () => _openRoom(context, room, isOwner),
          )
        : RoomListCard(
            room: room,
            showFavorite: !isOwner,
            onFavoriteTap: () => context.read<RoomListBloc>().add(
              ToggleFavoriteEvent(roomId: room.id),
            ),
            onTap: () => _openRoom(context, room, isOwner),
          );
    return card;
  }
}

void _openRoom(BuildContext context, RoomModel room, bool isOwner) {
  if (room.hasPassword && !isOwner) {
    showRoomPasswordSheet(context, room);
  } else {
    AudioRoomAppOverlay.openRoom(room.id);
  }
}
