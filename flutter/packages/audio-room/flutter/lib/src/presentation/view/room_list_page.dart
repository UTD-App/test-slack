import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../audio_room_routes.dart';
import '../bloc/room_list_bloc.dart';
import '../widgets/room_card.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<RoomListBloc>();
    bloc.add(const LoadRoomsEvent());
    bloc.add(const LoadCategoriesEvent());
    bloc.add(const LoadMyRoomEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('audio_room.title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AudioRoomRoutes.createPath),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'audio_room.search_hint',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              onSubmitted: (query) {
                context
                    .read<RoomListBloc>()
                    .add(SearchRoomsEvent(query: query));
              },
            ),
          ),
          _CategoriesBar(),
          Expanded(child: _RoomGrid()),
        ],
      ),
    );
  }
}

class _CategoriesBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomListBloc, RoomListState>(
      buildWhen: (prev, curr) =>
          prev.categories != curr.categories ||
          prev.selectedCategoryId != curr.selectedCategoryId,
      builder: (context, state) {
        if (state.categoriesState != RequestState.loaded) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 40.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: state.categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final isSelected = isAll
                  ? state.selectedCategoryId == null
                  : state.categories[index - 1].id ==
                      state.selectedCategoryId;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    isAll ? 'audio_room.all' : state.categories[index - 1].name,
                  ),
                  onSelected: (_) {
                    context.read<RoomListBloc>().add(
                          SelectCategoryEvent(
                            categoryId:
                                isAll ? null : state.categories[index - 1].id,
                          ),
                        );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RoomGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomListBloc, RoomListState>(
      builder: (context, state) {
        switch (state.roomsState) {
          case RequestState.loading:
            return const Center(child: CircularProgressIndicator());
          case RequestState.error:
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message ?? 'audio_room.error'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => context
                        .read<RoomListBloc>()
                        .add(const LoadRoomsEvent()),
                    child: const Text('audio_room.retry'),
                  ),
                ],
              ),
            );
          case RequestState.empty:
            return const Center(child: Text('audio_room.empty'));
          case RequestState.loaded:
            return RefreshIndicator(
              onRefresh: () async {
                context.read<RoomListBloc>().add(const LoadRoomsEvent());
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification &&
                      notification.metrics.extentAfter < 200 &&
                      state.hasMore) {
                    context
                        .read<RoomListBloc>()
                        .add(const LoadMoreRoomsEvent());
                  }
                  return false;
                },
                child: GridView.builder(
                  padding: EdgeInsets.all(12.r),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: state.rooms.length,
                  itemBuilder: (context, index) {
                    return RoomCard(
                      room: state.rooms[index],
                      onTap: () => context.push(
                        AudioRoomRoutes.roomPath(state.rooms[index].id),
                      ),
                    );
                  },
                ),
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
