import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../bloc/room_list/room_list_bloc.dart';
import 'room_sort_button.dart';
import 'room_view_toggle.dart';

class RoomToolbar extends StatelessWidget {
  const RoomToolbar({super.key});

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
              RoomSortButton(sortBy: state.sortBy),
              const Spacer(),
              RoomViewToggle(isGrid: state.isGridView),
            ],
          ),
        );
      },
    );
  }
}
