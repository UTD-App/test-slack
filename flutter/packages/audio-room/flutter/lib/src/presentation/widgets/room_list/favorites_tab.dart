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
import 'room_empty_state.dart';
import 'room_error_state.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = CacheManager.getUserData()?['id'] as int?;

    return BlocBuilder<RoomListBloc, RoomListState>(
      buildWhen: (prev, curr) =>
          prev.favoriteRooms != curr.favoriteRooms ||
          prev.favoritesState != curr.favoritesState ||
          prev.favoritesSearchQuery != curr.favoritesSearchQuery ||
          prev.isGridView != curr.isGridView,
      builder: (context, state) {
        switch (state.favoritesState) {
          case RequestState.loading:
            return const Center(child: CircularProgressIndicator());
          case RequestState.error:
            return RoomErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<RoomListBloc>().add(const LoadFavoritesEvent()),
            );
          case RequestState.loaded:
            final query = state.favoritesSearchQuery?.toLowerCase() ?? '';
            final filtered = query.isEmpty
                ? state.favoriteRooms
                : state.favoriteRooms
                      .where(
                        (r) =>
                            r.roomName.toLowerCase().contains(query) ||
                            r.numId.toString().contains(query),
                      )
                      .toList();

            if (filtered.isEmpty) {
              return RoomEmptyState(
                icon: Icons.favorite_border_rounded,
                message: context.tr(AudioRoomKeys.noFavorites),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<RoomListBloc>().add(const LoadFavoritesEvent());
              },
              child: state.isGridView
                  ? _buildGrid(context, filtered, myId)
                  : _buildList(context, filtered, myId),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<RoomModel> rooms, int? myId) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(14.r, 8.r, 14.r, 14.r),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.82,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final isOwner = myId != null && myId == room.ownerId;
        return RoomCard(
          room: room,
          showFavorite: true,
          onFavoriteTap: () => context.read<RoomListBloc>().add(
            ToggleFavoriteEvent(roomId: room.id),
          ),
          onTap: () => _openRoom(context, room, isOwner),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<RoomModel> rooms, int? myId) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(14.r, 8.r, 14.r, 14.r),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final isOwner = myId != null && myId == room.ownerId;
        return Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: RoomListCard(
            room: room,
            showFavorite: true,
            onFavoriteTap: () => context.read<RoomListBloc>().add(
              ToggleFavoriteEvent(roomId: room.id),
            ),
            onTap: () => _openRoom(context, room, isOwner),
          ),
        );
      },
    );
  }
}

void _openRoom(BuildContext context, RoomModel room, bool isOwner) {
  if (room.hasPassword && !isOwner) {
    showRoomPasswordSheet(context, room);
  } else {
    AudioRoomAppOverlay.openRoom(room.id);
  }
}
