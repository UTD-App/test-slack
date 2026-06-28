import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization.dart';

import 'package:utd_app/network/models/api_response.dart';

import '../../audio_room_routes.dart';
import '../widgets/overlay/audio_room_app_overlay.dart';
import '../../audio_room_strings.dart';
import '../../data/audio_room_api_service.dart';
import '../../data/audio_room_remote_datasource.dart';
import '../../domain/audio_room_repository.dart';
import '../../data/audio_room_repository_impl.dart';
import '../bloc/room_list/room_list_bloc.dart';
import '../widgets/room/shared/room_assets.dart';
import '../widgets/room_list/room_search_bar.dart';
import '../widgets/room_list/room_toolbar.dart';
import '../widgets/room_list/rooms_tab.dart';
import '../widgets/room_list/favorites_tab.dart';

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
    _refreshAll();
    AudioRoomAppOverlay.onRoomClosed = _refreshAll;
  }

  @override
  void dispose() {
    if (AudioRoomAppOverlay.onRoomClosed == _refreshAll) {
      AudioRoomAppOverlay.onRoomClosed = null;
    }
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    final bloc = context.read<RoomListBloc>();
    bloc.add(const LoadRoomsEvent());
    bloc.add(const LoadCategoriesEvent());
    bloc.add(const LoadMyRoomEvent());
    bloc.add(const LoadFavoritesEvent());
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
          await context.push(AudioRoomRoutes.createPath);
          if (mounted) _refreshAll();
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
          RoomSearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
          const RoomToolbar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [RoomsTab(), FavoritesTab()],
            ),
          ),
        ],
      ),
    );
  }
}
