import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/enums.dart';

import '../../../audio_room_strings.dart';
import '../../bloc/room_list/room_list_bloc.dart';

class RoomCategoriesBar extends StatelessWidget {
  const RoomCategoriesBar({super.key});

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
