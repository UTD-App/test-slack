import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../bloc/room_list_bloc.dart';

class RoomViewToggle extends StatelessWidget {
  final bool isGrid;

  const RoomViewToggle({super.key, required this.isGrid});

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
