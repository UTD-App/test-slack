import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/enums.dart';

import 'package:utd_app/network/models/api_response.dart';

import '../../audio_room_routes.dart';
import '../widgets/audio_room_app_overlay.dart';
import '../../audio_room_strings.dart';
import '../../data/audio_room_api_service.dart';
import '../../data/audio_room_remote_datasource.dart';
import '../../domain/audio_room_repository.dart';
import '../../domain/room_model.dart';
import '../bloc/room_list_bloc.dart';
import '../widgets/room_card.dart';
import '../widgets/room_list_card.dart';
import '../widgets/room/room_assets.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isLoadingMyRoom = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    final bloc = context.read<RoomListBloc>();
    bloc.add(const LoadRoomsEvent());
    bloc.add(const LoadCategoriesEvent());
    bloc.add(const LoadMyRoomEvent());
    bloc.add(const LoadFavoritesEvent());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _searchController.clear();
      if (_tabController.index == 0) {
        context.read<RoomListBloc>().add(const SearchRoomsEvent(query: ''));
      } else {
        context.read<RoomListBloc>().add(const SearchFavoritesEvent(query: ''));
      }
    }
  }

  Future<void> _onCreateOrEnterMyRoom() async {
    if (_isLoadingMyRoom) return;
    setState(() => _isLoadingMyRoom = true);

    final repository = AudioRoomRepositoryImpl(
      remoteDataSource: AudioRoomRemoteDataSourceImpl(
        apiService: AudioRoomApiService(),
      ),
    );
    final result = await repository.getMyRoom();
    if (!mounted) return;
    setState(() => _isLoadingMyRoom = false);

    switch (result) {
      case Success(data: final data):
        if (data.data != null) {
          AudioRoomAppOverlay.openRoom(data.data!.id);
        } else {
          context.push(AudioRoomRoutes.createPath);
        }
      case Failure(message: final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (_tabController.index == 0) {
        context.read<RoomListBloc>().add(SearchRoomsEvent(query: query));
      } else {
        context.read<RoomListBloc>().add(SearchFavoritesEvent(query: query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(AudioRoomKeys.title),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20.sp),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          GestureDetector(
            onTap: _onCreateOrEnterMyRoom,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: _isLoadingMyRoom
                  ? SizedBox(
                      width: 28.r,
                      height: 28.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Image.asset(
                      RoomAssets.createRoom,
                      width: 28.r,
                      height: 28.r,
                    ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(42.h),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: primary,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              labelStyle: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
              padding: EdgeInsets.all(3.r),
              tabs: [
                Tab(
                  height: 34.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grid_view_rounded, size: 16.r),
                      SizedBox(width: 6.w),
                      Text(context.tr(AudioRoomKeys.rooms)),
                    ],
                  ),
                ),
                Tab(
                  height: 34.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_rounded, size: 16.r),
                      SizedBox(width: 6.w),
                      Text(context.tr(AudioRoomKeys.favorites)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 10.h),
          _SearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
          const _Toolbar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_RoomsTab(), const _FavoritesTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade200,
          ),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.tr(AudioRoomKeys.searchByNameOrId),
            hintStyle: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12.w, right: 8.w),
              child: Icon(
                Icons.search_rounded,
                size: 20.r,
                color: Colors.grey.shade400,
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 40.w),
            suffixIcon: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14.r,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            suffixIconConstraints: BoxConstraints(minWidth: 32.w),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
          style: TextStyle(fontSize: 14.sp),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomListBloc, RoomListState>(
      buildWhen: (prev, curr) =>
          prev.sortBy != curr.sortBy || prev.isGridView != curr.isGridView,
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
          child: Row(
            children: [
              _SortButton(sortBy: state.sortBy),
              const Spacer(),
              _ViewToggle(isGrid: state.isGridView),
            ],
          ),
        );
      },
    );
  }
}

class _SortButton extends StatelessWidget {
  final String sortBy;

  const _SortButton({required this.sortBy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final label = switch (sortBy) {
      'newest' => context.tr(AudioRoomKeys.sortByNewest),
      'oldest' => context.tr(AudioRoomKeys.sortByOldest),
      _ => context.tr(AudioRoomKeys.sortByVisitors),
    };

    return PopupMenuButton<String>(
      onSelected: (value) {
        context.read<RoomListBloc>().add(ChangeSortEvent(sortBy: value));
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      elevation: 4,
      itemBuilder: (ctx) => [
        _sortItem(
          context,
          'visitors',
          Icons.people_alt_rounded,
          AudioRoomKeys.sortByVisitors,
        ),
        _sortItem(
          context,
          'newest',
          Icons.schedule_rounded,
          AudioRoomKeys.sortByNewest,
        ),
        _sortItem(
          context,
          'oldest',
          Icons.history_rounded,
          AudioRoomKeys.sortByOldest,
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: primary.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 16.r, color: primary),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortItem(
    BuildContext context,
    String value,
    IconData icon,
    String key,
  ) {
    final isActive = sortBy == value;
    final primary = Theme.of(context).colorScheme.primary;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: isActive
                  ? primary.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              size: 16.r,
              color: isActive ? primary : Colors.grey,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            context.tr(key),
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? primary : null,
              fontSize: 13.sp,
            ),
          ),
          if (isActive) ...[
            const Spacer(),
            Icon(Icons.check_rounded, size: 18.r, color: primary),
          ],
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isGrid;

  const _ViewToggle({required this.isGrid});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(
            icon: Icons.grid_view_rounded,
            active: isGrid,
            primary: primary,
            onTap: () => context.read<RoomListBloc>().add(
              const ChangeViewModeEvent(isGrid: true),
            ),
          ),
          SizedBox(width: 2.w),
          _toggleBtn(
            icon: Icons.view_list_rounded,
            active: !isGrid,
            primary: primary,
            onTap: () => context.read<RoomListBloc>().add(
              const ChangeViewModeEvent(isGrid: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn({
    required IconData icon,
    required bool active,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(7.r),
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          size: 18.r,
          color: active ? Colors.white : Colors.grey,
        ),
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
        if (state.categoriesState != RequestState.loaded ||
            state.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        final primary = Theme.of(context).colorScheme.primary;

        return SizedBox(
          height: 38.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            itemCount: state.categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final isSelected = isAll
                  ? state.selectedCategoryId == null
                  : state.categories[index - 1].id == state.selectedCategoryId;
              final label = isAll
                  ? context.tr(AudioRoomKeys.all)
                  : state.categories[index - 1].name;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: GestureDetector(
                  onTap: () {
                    context.read<RoomListBloc>().add(
                      SelectCategoryEvent(
                        categoryId: isAll
                            ? null
                            : state.categories[index - 1].id,
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary
                          : primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => _EnterRoomPasswordSheet(room: room),
  );
}

class _EnterRoomPasswordSheet extends StatefulWidget {
  final RoomModel room;
  const _EnterRoomPasswordSheet({required this.room});

  @override
  State<_EnterRoomPasswordSheet> createState() =>
      _EnterRoomPasswordSheetState();
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
          AudioRoomAppOverlay.openRoom(widget.room.id, verifiedRoom: data.data);
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
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24.w,
        right: 24.w,
        top: 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_rounded, size: 28.r, color: primary),
          ),
          SizedBox(height: 16.h),
          Text(
            widget.room.roomName,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          Text(
            context.tr(AudioRoomKeys.passwordHint),
            style: TextStyle(fontSize: 13.sp, color: Colors.grey),
          ),
          if (_error != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 13.sp, color: Colors.red),
              ),
            ),
          ],
          SizedBox(height: 24.h),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 20,
            autofocus: true,
            textAlign: TextAlign.center,
            enabled: !_loading,
            style: TextStyle(
              fontSize: 20.sp,
              letterSpacing: 6,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: context.tr(AudioRoomKeys.enterPassword),
              hintStyle: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w400,
              ),
              counterText: '',
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      height: 22.r,
                      width: 22.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.tr(AudioRoomKeys.enter),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _RoomsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoriesBar(),
        SizedBox(height: 4.h),
        Expanded(child: _RoomGrid()),
      ],
    );
  }
}

class _RoomGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final myId = CacheManager.getUserData()?['id'] as int?;

    return BlocBuilder<RoomListBloc, RoomListState>(
      builder: (context, state) {
        switch (state.roomsState) {
          case RequestState.loading:
            return const Center(child: CircularProgressIndicator());
          case RequestState.error:
            return _ErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<RoomListBloc>().add(const LoadRoomsEvent()),
            );
          case RequestState.empty:
            return _EmptyState(
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
    _showPasswordSheet(context, room);
  } else {
    AudioRoomAppOverlay.openRoom(room.id);
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

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
            return _ErrorState(
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
              return _EmptyState(
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36.r, color: Colors.grey.shade400),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorState({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 32.r,
              color: Colors.red.shade300,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            message ?? context.tr(AudioRoomKeys.error),
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.tr(AudioRoomKeys.retry)),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
