import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/enums.dart';

import 'package:utd_app/network/models/api_response.dart';

import '../../audio_room_routes.dart';
import '../../audio_room_strings.dart';
import '../../data/audio_room_api_service.dart';
import '../../data/audio_room_remote_datasource.dart';
import '../../domain/audio_room_repository.dart';
import '../../domain/room_model.dart';
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
        title: Text(context.tr(AudioRoomKeys.title)),
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
                hintText: context.tr(AudioRoomKeys.searchHint),
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
                    isAll ? context.tr(AudioRoomKeys.all) : state.categories[index - 1].name,
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

void _showPasswordSheet(BuildContext context, RoomModel room) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (_) => _EnterRoomPasswordSheet(room: room),
  );
}

class _EnterRoomPasswordSheet extends StatefulWidget {
  final RoomModel room;
  const _EnterRoomPasswordSheet({required this.room});

  @override
  State<_EnterRoomPasswordSheet> createState() => _EnterRoomPasswordSheetState();
}

class _EnterRoomPasswordSheetState extends State<_EnterRoomPasswordSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  late final AudioRoomRepository _repository = AudioRoomRepositoryImpl(
    remoteDataSource: AudioRoomRemoteDataSourceImpl(
      apiService: AudioRoomApiService(),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _controller.text.trim();
    if (password.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _repository.enterRoom(
      widget.room.id,
      password: password,
    );

    if (!mounted) return;

    switch (result) {
      case Success(data: final data):
        if (data.data != null) {
          Navigator.pop(context);
          context.push(
            AudioRoomRoutes.roomPath(widget.room.id),
            extra: data.data,
          );
        } else {
          setState(() {
            _loading = false;
            _error = data.message;
          });
        }
      case Failure(message: final message):
        setState(() {
          _loading = false;
          _error = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20.w,
        right: 20.w,
        top: 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 40.r, color: Colors.grey),
          SizedBox(height: 12.h),
          Text(
            widget.room.roomName,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.h),
          Text(
            context.tr(AudioRoomKeys.passwordHint),
            style: TextStyle(fontSize: 13.sp, color: Colors.grey),
          ),
          if (_error != null) ...[
            SizedBox(height: 8.h),
            Text(
              _error!,
              style: TextStyle(fontSize: 13.sp, color: Colors.red),
            ),
          ],
          SizedBox(height: 20.h),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 20,
            autofocus: true,
            textAlign: TextAlign.center,
            enabled: !_loading,
            style: TextStyle(fontSize: 18.sp, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: context.tr(AudioRoomKeys.enterPassword),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      height: 20.r,
                      width: 20.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.tr(AudioRoomKeys.enter),
                      style: TextStyle(fontSize: 15.sp)),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
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
                  Text(state.message ?? context.tr(AudioRoomKeys.error)),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => context
                        .read<RoomListBloc>()
                        .add(const LoadRoomsEvent()),
                    child: Text(context.tr(AudioRoomKeys.retry)),
                  ),
                ],
              ),
            );
          case RequestState.empty:
            return Center(child: Text(context.tr(AudioRoomKeys.empty)));
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
                    final room = state.rooms[index];
                    return RoomCard(
                      room: room,
                      onTap: () {
                        final myId = CacheManager.getUserData()?['id'] as int?;
                        final isOwner = myId != null && myId == room.ownerId;
                        if (room.hasPassword && !isOwner) {
                          _showPasswordSheet(context, room);
                        } else {
                          context.push(AudioRoomRoutes.roomPath(room.id));
                        }
                      },
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
