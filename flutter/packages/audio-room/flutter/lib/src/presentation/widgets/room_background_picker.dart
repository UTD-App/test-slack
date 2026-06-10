import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoomBackgroundPicker extends StatelessWidget {
  final List<String> backgrounds;
  final String? selectedBackground;
  final ValueChanged<String> onSelected;

  const RoomBackgroundPicker({
    super.key,
    required this.backgrounds,
    this.selectedBackground,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (backgrounds.isEmpty) {
      return const Center(child: Text('audio_room.no_backgrounds'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(8.r),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
      ),
      itemCount: backgrounds.length,
      itemBuilder: (context, index) {
        final bg = backgrounds[index];
        final isSelected = bg == selectedBackground;

        return GestureDetector(
          onTap: () => onSelected(bg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    )
                  : null,
              image: DecorationImage(
                image: NetworkImage(bg),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}
