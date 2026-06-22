import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../audio_room_strings.dart';
import '../../bloc/room_list_bloc.dart';

class RoomSortButton extends StatelessWidget {
  final String sortBy;

  const RoomSortButton({super.key, required this.sortBy});

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
